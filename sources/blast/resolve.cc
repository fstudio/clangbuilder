///
#include "resolve.hpp"
#include <winioctl.h>
#include <pathcch.h>
#include <memory>
#include <vector>
#include <charconv>
#include <ShlObj.h>
#include "../include/mapview.hpp"
#include "../include/comutils.hpp"
#include "reparsepoint.hpp"

std::wstring guidencode(const GUID &guid) {
  wchar_t wbuf[64];
  swprintf_s(wbuf, L"{%08X-%04X-%04X-%02X%02X%02X%02X%02X%02X%02X%02X}",
             guid.Data1, guid.Data2, guid.Data3, guid.Data4[0], guid.Data4[1],
             guid.Data4[2], guid.Data4[3], guid.Data4[4], guid.Data4[5],
             guid.Data4[6], guid.Data4[7]);
  return std::wstring(wbuf);
}

namespace inquisitive {

bool PathCanonicalizeEx(std::wstring_view sv, std::wstring &path) {
  LPWSTR lpPart;
  if (sv.size() > 4 && sv[0] == '\\' && sv[1] == '\\' && sv[3] == '\\') {
    sv.remove_prefix(4);
  }
  auto N = GetFullPathNameW(sv.data(), 0, nullptr, nullptr);
  if (N == 0) {
    return false;
  }
  path.resize(N + 1);
  N = GetFullPathNameW(sv.data(), N + 1, &path[0], &lpPart);
  if (N == 0) {
    return false;
  }
  path.resize(N);
  if (path.size() > 2 && (path.back() == L'\\' || path.back() == L'/')) {
    path.pop_back();
  }
  return true;
}

std::optional<file_target_t> ResolveTarget(std::wstring_view sv,
                                           base::error_code &ec) {
#ifndef _M_X64
  clangbuilder::FsRedirection fdr;
#endif
  auto FileHandle = CreateFileW(
      sv.data(), 0, FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
      nullptr, OPEN_EXISTING,
      FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OPEN_REPARSE_POINT, nullptr);
  if (FileHandle == INVALID_HANDLE_VALUE) {
    ec = base::make_system_error_code();
    return std::nullopt;
  }
  BYTE mxbuf[MAXIMUM_REPARSE_DATA_BUFFER_SIZE] = {0};
  auto rebuf = reinterpret_cast<PREPARSE_DATA_BUFFER>(mxbuf);
  DWORD dwlen = 0;
  if (DeviceIoControl(FileHandle, FSCTL_GET_REPARSE_POINT, nullptr, 0, rebuf,
                      MAXIMUM_REPARSE_DATA_BUFFER_SIZE, &dwlen,
                      nullptr) != TRUE) {
    CloseHandle(FileHandle);
    return std::nullopt;
  }
  CloseHandle(FileHandle);

  file_target_t file;
  switch (rebuf->ReparseTag) {
  case IO_REPARSE_TAG_SYMLINK: {
    file.type = SymbolicLink;
    auto wstr =
        rebuf->SymbolicLinkReparseBuffer.PathBuffer +
        (rebuf->SymbolicLinkReparseBuffer.SubstituteNameOffset / sizeof(WCHAR));
    auto wlen =
        rebuf->SymbolicLinkReparseBuffer.SubstituteNameLength / sizeof(WCHAR);
    if (wlen >= 4 && wstr[0] == L'\\' && wstr[1] == L'?' && wstr[2] == L'?' &&
        wstr[3] == L'\\') {
      /* Starts with \??\ */
      if (wlen >= 6 &&
          ((wstr[4] >= L'A' && wstr[4] <= L'Z') ||
           (wstr[4] >= L'a' && wstr[4] <= L'z')) &&
          wstr[5] == L':' && (wlen == 6 || wstr[6] == L'\\')) {
        /* \??\<drive>:\ */
        wstr += 4;
        wlen -= 4;

      } else if (wlen >= 8 && (wstr[4] == L'U' || wstr[4] == L'u') &&
                 (wstr[5] == L'N' || wstr[5] == L'n') &&
                 (wstr[6] == L'C' || wstr[6] == L'c') && wstr[7] == L'\\') {
        /* \??\UNC\<server>\<share>\ - make sure the final path looks like */
        /* \\<server>\<share>\ */
        wstr += 6;
        wstr[0] = L'\\';
        wlen -= 6;
      }
    }
    file.path.assign(wstr, wlen);
  } break;
  case IO_REPARSE_TAG_MOUNT_POINT: {
    file.type = MountPoint;
    auto wstr =
        rebuf->MountPointReparseBuffer.PathBuffer +
        (rebuf->MountPointReparseBuffer.SubstituteNameOffset / sizeof(WCHAR));
    auto wlen =
        rebuf->MountPointReparseBuffer.SubstituteNameLength / sizeof(WCHAR);
    /* Only treat junctions that look like \??\<drive>:\ as symlink. */
    /* Junctions can also be used as mount points, like \??\Volume{<guid>}, */
    /* but that's confusing for programs since they wouldn't be able to */
    /* actually understand such a path when returned by uv_readlink(). */
    /* UNC paths are never valid for junctions so we don't care about them. */
    if (!(wlen >= 6 && wstr[0] == L'\\' && wstr[1] == L'?' && wstr[2] == L'?' &&
          wstr[3] == L'\\' &&
          ((wstr[4] >= L'A' && wstr[4] <= L'Z') ||
           (wstr[4] >= L'a' && wstr[4] <= L'z')) &&
          wstr[5] == L':' && (wlen == 6 || wstr[6] == L'\\'))) {
      return std::nullopt;
    }

    /* Remove leading \??\ */
    wstr += 4;
    wlen -= 4;
    file.path.assign(wstr, wlen);
  } break;
  case IO_REPARSE_TAG_APPEXECLINK: {
    // L"AppExec link";
    file.type = AppExecLink;
    if (rebuf->AppExecLinkReparseBuffer.StringCount >= 3) {
      LPWSTR szString = (LPWSTR)rebuf->AppExecLinkReparseBuffer.StringList;
      std::vector<LPWSTR> strv;
      for (ULONG i = 0; i < rebuf->AppExecLinkReparseBuffer.StringCount; i++) {
        strv.push_back(szString);
        szString += wcslen(szString) + 1;
      }
      appexeclink_t alink{strv[0], strv[1], strv[2]};
      file.av = alink;
      file.path = strv[2];
      // to get value auto x=std::get<appexeclink_t>(file.av);
    }
  } break;
  case IO_REPARSE_TAG_AF_UNIX:
    // L"Unix domain socket";
    file.type = AFUnix;
    file.path = sv;
    break;
  case IO_REPARSE_TAG_ONEDRIVE:
    // L"OneDrive file";
    file.type = OneDrive;
    file.path = sv;
    break;
  case IO_REPARSE_TAG_FILE_PLACEHOLDER:
    // L"Placeholder file";
    file.type = Placeholder;
    file.path = sv;

    break;
  case IO_REPARSE_TAG_STORAGE_SYNC:
    // L"Storage sync file";
    file.type = StorageSync;
    file.path = sv;
    break;
  case IO_REPARSE_TAG_PROJFS:
    // L"Projected File";
    file.type = ProjFS;
    file.path = sv;
    break;
  case IO_REPARSE_TAG_WIM: {
    file.type = WimImage;
    file.path = sv;
    reparse_wim_t wim;
    wim.guid = guidencode(rebuf->WimImageReparseBuffer.ImageGuid);
    wim.hash = hexencode(reinterpret_cast<const char *>(
                             rebuf->WimImageReparseBuffer.ImagePathHash),
                         sizeof(rebuf->WimImageReparseBuffer.ImagePathHash));
    file.av = wim;
  } break;
  case IO_REPARSE_TAG_WOF: {
    // wof.sys Windows Overlay File System Filter Driver
    file.type = Wof;
    file.path = sv;
    reparse_wof_t wof;
    wof.algorithm = rebuf->WofReparseBuffer.FileInfo_Algorithm;
    wof.version = rebuf->WofReparseBuffer.FileInfo_Version;
    wof.wofprovider = rebuf->WofReparseBuffer.Wof_Provider;
    wof.wofversion = rebuf->WofReparseBuffer.Wof_Version;
    file.av = wof;
  } break;
  case IO_REPARSE_TAG_WCI: {
    // wcifs.sys Windows Container Isolation FS Filter Driver
    file.type = Wcifs;
    file.path = sv;
    reparse_wcifs_t wci;
    wci.WciName.assign(rebuf->WcifsReparseBuffer.WciName,
                       rebuf->WcifsReparseBuffer.WciNameLength);
    wci.Version = rebuf->WcifsReparseBuffer.Version;
    wci.Reserved = rebuf->WcifsReparseBuffer.Reserved;
    wci.LookupGuid = guidencode(rebuf->WcifsReparseBuffer.LookupGuid);
    file.av = wci;
  } break;
  case IO_REPARSE_TAG_HSM:
    break;
  default:
    break;
  }
  if (file.type == HardLink) {
    return std::nullopt;
  }
  return std::make_optional<file_target_t>(file);
}

inline bool HardLinkEqual(std::wstring_view lh, std::wstring_view rh) {
  if (lh.size() != rh.size()) {
    return false;
  }
  return _wcsnicmp(lh.data(), rh.data(), rh.size()) == 0;
}

// File hardlinks.
std::optional<file_links_t> ResolveLinks(std::wstring_view sv,
                                         base::error_code &ec) {
#ifndef _M_X64
  FsRedirection fsr;
#endif
  std::wstring self;
  if (!PathCanonicalizeEx(sv, self)) {
    ec = base::make_system_error_code();
    return std::nullopt;
  }
  auto FileHandle = CreateFileW(self.data(),           // file to open
                                GENERIC_READ,          // open for reading
                                FILE_SHARE_READ,       // share for reading
                                NULL,                  // default security
                                OPEN_EXISTING,         // existing file only
                                FILE_ATTRIBUTE_NORMAL, // normal file
                                NULL);
  if (FileHandle == INVALID_HANDLE_VALUE) {
    return std::nullopt;
  }
  BY_HANDLE_FILE_INFORMATION bi;
  if (GetFileInformationByHandle(FileHandle, &bi) != TRUE) {
    CloseHandle(FileHandle);
    return std::nullopt;
  }
  CloseHandle(FileHandle);
  LARGE_INTEGER li;
  li.HighPart = bi.nFileIndexHigh;
  li.LowPart = bi.nFileIndexLow;
  if (bi.nNumberOfLinks <= 1) {
    /// on other hardlinks
    return std::nullopt;
  }
  auto linkPath = std::make_unique<wchar_t[]>(PATHCCH_MAX_CCH);
  DWORD dwlen = PATHCCH_MAX_CCH;
  auto hFind = FindFirstFileNameW(self.c_str(), 0, &dwlen, linkPath.get());
  if (hFind == INVALID_HANDLE_VALUE) {
    ec = base::make_system_error_code();
    return std::nullopt;
  }
  file_links_t link;

  do {
    auto s = self.substr(0, 2);
    s.append(linkPath.get(), dwlen - 1);
    // priv::verbose(L"Find: %s %zu %zu\n", s, s.size(), self.size());
    if (!HardLinkEqual(s, self)) {
      link.links.push_back(s);
    }
    dwlen = PATHCCH_MAX_CCH;
  } while (FindNextFileNameW(hFind, &dwlen, linkPath.get()));
  FindClose(hFind);
  link.self = self;
  return std::make_optional<file_links_t>(link);
}

} // namespace inquisitive