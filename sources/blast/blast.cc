#include "blast.hpp"
#include <Strsafe.h>
/// GetFullPathNameW
///

/*
#define IO_REPARSE_TAG_MOUNT_POINT              (0xA0000003L)
#define IO_REPARSE_TAG_HSM                      (0xC0000004L)
#define IO_REPARSE_TAG_HSM2                     (0x80000006L)
#define IO_REPARSE_TAG_SIS                      (0x80000007L)
#define IO_REPARSE_TAG_WIM                      (0x80000008L)
#define IO_REPARSE_TAG_CSV                      (0x80000009L)
#define IO_REPARSE_TAG_DFS                      (0x8000000AL)
#define IO_REPARSE_TAG_SYMLINK                  (0xA000000CL)
#define IO_REPARSE_TAG_DFSR                     (0x80000012L)
#define IO_REPARSE_TAG_DEDUP                    (0x80000013L)
#define IO_REPARSE_TAG_NFS                      (0x80000014L)
#define IO_REPARSE_TAG_FILE_PLACEHOLDER         (0x80000015L)
#define IO_REPARSE_TAG_WOF                      (0x80000017L)
#define IO_REPARSE_TAG_WCI                      (0x80000018L)
#define IO_REPARSE_TAG_WCI_1                    (0x90001018L)
#define IO_REPARSE_TAG_GLOBAL_REPARSE           (0xA0000019L)
#define IO_REPARSE_TAG_CLOUD                    (0x9000001AL)
#define IO_REPARSE_TAG_CLOUD_1                  (0x9000101AL)
#define IO_REPARSE_TAG_CLOUD_2                  (0x9000201AL)
#define IO_REPARSE_TAG_CLOUD_3                  (0x9000301AL)
#define IO_REPARSE_TAG_CLOUD_4                  (0x9000401AL)
#define IO_REPARSE_TAG_CLOUD_5                  (0x9000501AL)
#define IO_REPARSE_TAG_CLOUD_6                  (0x9000601AL)
#define IO_REPARSE_TAG_CLOUD_7                  (0x9000701AL)
#define IO_REPARSE_TAG_CLOUD_8                  (0x9000801AL)
#define IO_REPARSE_TAG_CLOUD_9                  (0x9000901AL)
#define IO_REPARSE_TAG_CLOUD_A                  (0x9000A01AL)
#define IO_REPARSE_TAG_CLOUD_B                  (0x9000B01AL)
#define IO_REPARSE_TAG_CLOUD_C                  (0x9000C01AL)
#define IO_REPARSE_TAG_CLOUD_D                  (0x9000D01AL)
#define IO_REPARSE_TAG_CLOUD_E                  (0x9000E01AL)
#define IO_REPARSE_TAG_CLOUD_F                  (0x9000F01AL)
#define IO_REPARSE_TAG_CLOUD_MASK               (0x0000F000L)
#define IO_REPARSE_TAG_APPEXECLINK              (0x8000001BL)
#define IO_REPARSE_TAG_PROJFS                   (0x9000001CL)
#define IO_REPARSE_TAG_STORAGE_SYNC             (0x8000001EL)
#define IO_REPARSE_TAG_WCI_TOMBSTONE            (0xA000001FL)
#define IO_REPARSE_TAG_UNHANDLED                (0x80000020L)
#define IO_REPARSE_TAG_ONEDRIVE                 (0x80000021L)
#define IO_REPARSE_TAG_PROJFS_TOMBSTONE         (0xA0000022L)
#define IO_REPARSE_TAG_AF_UNIX                  (0x80000023L)

/// Windows Linux Subsystem
#define IO_REPARSE_TAG_LX_FIFO                  (0x80000024L)
#define IO_REPARSE_TAG_LX_CHR                   (0x80000025L)
#define IO_REPARSE_TAG_LX_BLK                   (0x80000026L)
*/

static LPCWSTR AppExecLinkParts[] = {
    L"AppPackageID",
    L"AppUserModelID",
    L"TargetPath",
};

struct RegKeyHelper {
  ~RegKeyHelper() {
    if (hKey != nullptr) {
      RegCloseKey(hKey);
    }
  }
  HKEY hKey{nullptr};
};

class ErrorMessage {
public:
  ErrorMessage(DWORD errid) : lastError(errid) {
    if (FormatMessageW(
            FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
            nullptr, errid, MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL),
            (LPWSTR)&buf, 0, nullptr) == 0) {
      buf = nullptr;
    }
  }
  ~ErrorMessage() {
    if (buf != nullptr) {
      LocalFree(buf);
    }
  }
  const wchar_t *message() const { return buf == nullptr ? L"unknwon" : buf; }
  DWORD LastError() const { return lastError; }

private:
  DWORD lastError;
  LPWSTR buf{nullptr};
};

bool IsWindowsVersionOrGreaterEx(WORD wMajorVersion, WORD wMinorVersion,
                                 DWORD buildNumber) {
  const wchar_t *currentVersion =
      LR"(SOFTWARE\Microsoft\Windows NT\CurrentVersion)";
  RegKeyHelper key;
  if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, currentVersion, 0, KEY_READ,
                    &(key.hKey)) != ERROR_SUCCESS) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"error: %s\n", err.message());
    return false;
  }
  DWORD wMajor, wMinor;
  DWORD type = 0;
  DWORD dwSizeM = sizeof(DWORD);
  if (RegGetValueW(key.hKey, nullptr, L"CurrentMajorVersionNumber",
                   RRF_RT_DWORD, &type, &wMajor, &dwSizeM) != ERROR_SUCCESS) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"error: %s\n", err.message());
    return false;
  }
  dwSizeM = sizeof(DWORD);
  if (RegGetValueW(key.hKey, nullptr, L"CurrentMinorVersionNumber",
                   RRF_RT_DWORD, &type, &wMinor, &dwSizeM) != ERROR_SUCCESS) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"error: %s\n", err.message());
    return false;
  }
  WCHAR buffer[32];
  DWORD dwSize = sizeof(buffer);
  if (RegGetValueW(key.hKey, nullptr, L"CurrentBuildNumber", RRF_RT_REG_SZ,
                   &type, buffer, &dwSize) != ERROR_SUCCESS) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"error: %s\n", err.message());
    return false;
  }
  wchar_t *w;
  auto bn = wcstol(buffer, &w, 10);
  if (wMajor < wMajorVersion) {
    return false;
  }
  if (wMajor > wMajorVersion) {
    return true;
  }
  if (wMinor > wMinorVersion) {
    return true;
  }
  if (wMinor < wMinorVersion) {
    return false;
  }
  return ((DWORD)bn >= buildNumber);
}

struct ReparseBuffer {
  ReparseBuffer() {
    data = reinterpret_cast<REPARSE_DATA_BUFFER *>(
        malloc(MAXIMUM_REPARSE_DATA_BUFFER_SIZE));
  }
  ~ReparseBuffer() {
    if (data != nullptr) {
      free(data);
    }
  }
  REPARSE_DATA_BUFFER *data{nullptr};
};

bool readlink(const std::wstring &symfile, std::wstring &realfile) {
  auto hFile = CreateFileW(
      symfile.c_str(), 0,
      FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, NULL,
      OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OPEN_REPARSE_POINT,
      NULL);
  if (hFile == INVALID_HANDLE_VALUE) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"CreateFileW: %s\n", err.message());
    return false;
  }
  ReparseBuffer rbuf;
  DWORD dwBytes = 0;
  if (DeviceIoControl(hFile, FSCTL_GET_REPARSE_POINT, nullptr, 0, rbuf.data,
                      MAXIMUM_REPARSE_DATA_BUFFER_SIZE, &dwBytes,
                      nullptr) != TRUE) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"DeviceIoControl: %s\n", err.message());
    CloseHandle(hFile);
    return false;
  }
  CloseHandle(hFile);
  switch (rbuf.data->ReparseTag) {
  case IO_REPARSE_TAG_SYMLINK: {
    auto wstr = rbuf.data->SymbolicLinkReparseBuffer.PathBuffer +
                (rbuf.data->SymbolicLinkReparseBuffer.SubstituteNameOffset /
                 sizeof(WCHAR));
    auto wlen = rbuf.data->SymbolicLinkReparseBuffer.SubstituteNameLength /
                sizeof(WCHAR);
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
    realfile.assign(wstr, wlen);
  } break;
  case IO_REPARSE_TAG_MOUNT_POINT: {
    auto wstr = rbuf.data->MountPointReparseBuffer.PathBuffer +
                (rbuf.data->MountPointReparseBuffer.SubstituteNameOffset /
                 sizeof(WCHAR));
    auto wlen =
        rbuf.data->MountPointReparseBuffer.SubstituteNameLength / sizeof(WCHAR);
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
      SetLastError(ERROR_SYMLINK_NOT_SUPPORTED);
      return false;
    }

    /* Remove leading \??\ */
    wstr += 4;
    wlen -= 4;
    realfile.assign(wstr, wlen);
  } break;
#ifdef IO_REPARSE_TAG_APPEXECLINK
  case IO_REPARSE_TAG_APPEXECLINK: {
    if (rbuf.data->AppExecLinkReparseBuffer.StringCount != 0) {
      LPWSTR szString = (LPWSTR)rbuf.data->AppExecLinkReparseBuffer.StringList;
      WCHAR szValue[0x8000];

      for (ULONG i = 0; i < rbuf.data->AppExecLinkReparseBuffer.StringCount;
           i++) {
        StringCchPrintf(szValue, _countof(szValue), L"%s: %s",
                        AppExecLinkParts[i], szString);
        if (wcscmp(AppExecLinkParts[i], L"TargetPath") == 0) {
          realfile = szString;
        }
        wprintf(L"%s\n", szValue);
        szString += wcslen(szString) + 1;
      }
    }
  } break;
#endif
  default:
    return false;
  }
  return true;
}

inline bool IsUserAdministratorsGroup()
/*++
Routine Description: This routine returns TRUE if the caller's
process is a member of the Administrators local group. Caller is NOT
expected to be impersonating anyone and is expected to be able to
open its own process and process token.
Arguments: None.
Return Value:
TRUE - Caller has Administrators local group.
FALSE - Caller does not have Administrators local group. --
*/
{
  BOOL b;
  SID_IDENTIFIER_AUTHORITY NtAuthority = SECURITY_NT_AUTHORITY;
  PSID AdministratorsGroup;
  b = AllocateAndInitializeSid(&NtAuthority, 2, SECURITY_BUILTIN_DOMAIN_RID,
                               DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0,
                               &AdministratorsGroup);
  if (b) {
    if (!CheckTokenMembership(NULL, AdministratorsGroup, &b)) {
      b = FALSE;
    }
    FreeSid(AdministratorsGroup);
  }

  return b == TRUE;
}

int readlinkall(int fn, wchar_t **files) {
  for (int i = 0; i < fn; i++) {
    std::wstring src;
    if (readlink(files[i], src)) {
      wprintf(L"%s -> %s\n", files[i], src.data());
    } else {
      wprintf(L"%s is hardlink\n", files[i]);
    }
  }
  return 0;
}

int AdministratorsElevateWait() {
  SHELLEXECUTEINFOW info;
  ZeroMemory(&info, sizeof(info));
  std::wstring exeself(32767, L'\0');
  if (!GetModuleFileNameW(nullptr, &exeself[0], 32767) == 0) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"GetModuleFileNameW: %s\n", err.message());
    return 1;
  }
  Arguments args;
  for (int i = 1; i < __argc; i++) {
    args.append(__wargv[i]);
  }
  info.lpFile = &exeself[0];
  info.lpParameters = args.str().data();
  info.lpVerb = L"runas";
  info.cbSize = sizeof(info);
  info.hwnd = NULL;
  info.nShow = SW_SHOWNORMAL;
  info.fMask = SEE_MASK_DEFAULT | SEE_MASK_NOCLOSEPROCESS;
  info.lpDirectory = nullptr;
  if (!ShellExecuteExW(&info)) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"GetFullPathNameW: %s\n", err.message());
    return 1;
  }
  WaitForSingleObject(info.hProcess, INFINITE);
  DWORD dwExit = 0;
  GetExitCodeProcess(info.hProcess, &dwExit);
  CloseHandle(info.hProcess);
  return dwExit;
}

int symlink(const wchar_t *src, const wchar_t *target) {
  DWORD dwflags = 0;
  if (IsWindowsVersionOrGreaterEx(10, 0, 14972)) {
    dwflags = SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE;
  } else {
    if (!IsUserAdministratorsGroup()) {
      return AdministratorsElevateWait();
    }
  }
  if (GetFileAttributesW(src) == INVALID_FILE_ATTRIBUTES) {
    fwprintf(stderr, L"file: %s not exists\n", src);
    return 1;
  }
  std::wstring buf(32767, L'\0');
  std::wstring buf2(32767, L'\0');
  auto lpSource = &buf[0];
  auto lpTarget = &buf2[0];
  if (GetFullPathNameW(src, 32767, lpSource, nullptr) == 0) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"GetFullPathNameW: %s\n", err.message());
    return 1;
  }
  if (GetFullPathNameW(target, 32767, lpTarget, nullptr) == 0) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"GetFullPathNameW: %s\n", err.message());
    return 1;
  }
  if (CreateSymbolicLinkW(lpTarget, lpSource, dwflags) != TRUE) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"create symlink error: %s\n", err.message());
    return 1;
  }
  wprintf(L"symlink: %s to %s success.\n", lpSource, lpTarget);
  return 0;
}

void usage() {
  const wchar_t *kusage = LR"(blast symbolic linker
    --readlink     read symbolic link file's source 
    --link         create a symlink
    --help         print usage and exit.
example:
    blast --link source target
    blast --readlin file1 file2 file3)";
  wprintf(L"%s\n", kusage);
}

/// blast --link source target
/// blast --readlink source
class DotComInitialize {
public:
  DotComInitialize() {
    if (FAILED(CoInitialize(NULL))) {
      throw std::runtime_error("CoInitialize failed");
    }
  }
  ~DotComInitialize() { CoUninitialize(); }
};

int wmain(int argc, wchar_t **argv) {
  DotComInitialize dot;
  setlocale(LC_ALL, ""); //
  if (argc >= 2 && wcscmp(argv[1], L"--help") == 0) {
    usage();
    return 0;
  }
  if (argc < 3) {
    wprintf(L"usage: %s <options> file\n", argv[0]);
    return 1;
  }
  if (wcscmp(argv[1], L"--readlink") == 0) {
    return readlinkall(argc - 2, argv + 2);
  }
  if (wcscmp(argv[1], L"--link") == 0 && argc >= 4) {
    return symlink(argv[2], argv[3]);
  }
  fwprintf(stderr, L"unsupport option: '%s'\n", argv[1]);
  return 1;
}