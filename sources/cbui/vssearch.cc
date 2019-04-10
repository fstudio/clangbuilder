//////////
#include "inc/vssearch.hpp"
#include "inc/json.hpp"
#include "inc/comutils.hpp"
#include "inc/vssetup.hpp"
#include <cctype>

bool FsVersion(std::wstring_view file, std::wstring &ver) {
  auto FileHandle =
      CreateFileW(file.data(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
                  nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (FileHandle == INVALID_HANDLE_VALUE) {
    return false;
  }
  uint8_t buf[4096] = {0}; // MUST U8
  DWORD dwr = 0;
  if (ReadFile(FileHandle, buf, 4096, &dwr, nullptr) != TRUE) {
    CloseHandle(FileHandle);
    return false;
  }
  CloseHandle(FileHandle);
  if (dwr < 3) {
    return false;
  }
  // UTF-16 LE
  if (buf[0] == 0xFF && buf[1] == 0xFE) {
    auto w = reinterpret_cast<wchar_t *>(buf + 2);
    auto l = (dwr - 2) / 2;
    ver.assign(w, l);
    w[l] = 0;
    return true;
  }
  // UTF-16 BE
  if (buf[0] == 0xFE && buf[1] == 0xFF) {
    auto w = reinterpret_cast<wchar_t *>(buf + 2);
    auto l = (dwr - 2) / 2;
    decltype(l) i = 0;
    for (; i < l; i++) {
      ver.push_back(_byteswap_ushort(w[i])); // Windows LE
    }
    return true;
  }
  // UTF-8 BOM
  if (buf[0] == 0xEF && buf[1] == 0xBB && buf[2] == 0xBF) {
    auto p = reinterpret_cast<char *>(buf + 3);
    std::string_view s(p, dwr - 3);
    ver = clangbuilder::utf8towide(s);
    return true;
  }
  // UTF-8 (ASCII)
  auto p = reinterpret_cast<char *>(buf);
  std::string_view s(p, dwr);
  ver = clangbuilder::utf8towide(s);
  return true;
}

std::wstring_view TrimPrefix(std::wstring_view s, std::wstring_view p) {
  if (s.size() > p.size() && s.compare(0, p.size(), p.data()) == 0) {
    return s.substr(p.size());
  }
  return s;
}

std::wstring FsVisualStudioVersion(std::wstring_view vsdir) {
  auto vsfile = base::strcat(vsdir, L"\\Version.txt");
  std::wstring ver;
  if (!FsVersion(vsfile, ver)) {
    return L"";
  }
  constexpr const std::wstring_view prefix = L"Visual Studio ";
  auto vp = TrimPrefix(ver, prefix);
  auto pos = vp.find(' ');
  if (pos == std::wstring_view::npos) {
    return std::wstring(vp);
  }
  return std::wstring(vp.data(), pos);
}

inline bool DirSkipFaster(const wchar_t *dir) {
  return (dir[0] == L'.' &&
          (dir[1] == L'\0' || (dir[1] == L'.' && dir[2] == L'\0')));
}

// Dirname like version
inline bool IsVersion(const wchar_t *dir) {
  auto p = dir;
  for (; *p; p++) {
    if (isxdigit(*p) == 0 && *p != L'.') {
      return false;
    }
  }
  return true;
}

std::wstring FsUniqueSubdirName(std::wstring_view dir) {
  bool success = false;

  WIN32_FIND_DATAW wfd;
  if (!dir.empty() && (dir.back() == L'\\' || dir.back() == L'/')) {
    dir.remove_suffix(1);
  }
  auto findstr = base::strcat(dir, L"\\*");
  HANDLE hFind = FindFirstFileW(findstr.c_str(), &wfd);
  if (hFind == INVALID_HANDLE_VALUE) {
    return L""; /// Not found
  }
  std::wstring name;
  do {
    if (wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
      if (!DirSkipFaster(wfd.cFileName) && IsVersion(wfd.cFileName)) {
        name = wfd.cFileName;
        break;
      }
    }
  } while (FindNextFileW(hFind, &wfd));
  FindClose(hFind);
  return name;
}

bool VisualStudioSeacher::EnterpriseWDK(std::wstring_view root,
                                        vssetup::VSInstance &vsi) {
  auto ej = base::strcat(root, L"\\config\\ewdk.json");
  if (!PathFileExistsW(ej.data())) {
    ej = base::strcat(root, L"\\config\\ewdk.template.json");
    if (!PathFileExistsW(ej.data())) {
      return false;
    }
  }
  try {
    std::ifstream fs;
    fs.open(ej, std::ios::binary);
    auto j = nlohmann::json::parse(fs);
    auto path = j["Path"].get<std::string>();
    auto ewdkdir = clangbuilder::utf8towide(path);
    auto vsdir =
        base::strcat(ewdkdir, L"\\Program Files\\Microsoft Visual Studio");
    auto product = FsUniqueSubdirName(vsdir);
    vsi.VSInstallLocation =
        base::strcat(vsdir, L"\\", product, L"\\BuildTools");
    vsi.Version = FsVisualStudioVersion(vsi.VSInstallLocation);
    auto incdir =
        base::strcat(ewdkdir, L"\\Program Files\\Windows Kits\\10\\include");
    auto sdkver = FsUniqueSubdirName(incdir);
    vsi.DisplayName = base::strcat(L"Visual Studio BuildTools ", product,
                                   L" (Enterprise WDK ", sdkver, L")");
    vsi.InstanceId.assign(L"VisualStudio.EWDK");
  } catch (const std::exception &e) {
    fprintf(stderr, "%s\n", e.what());
    return false;
  }
  return true;
}

bool VisualStudioSeacher::Execute(std::wstring_view root) {
  vssetup::VisualStudioNativeSearcher vns;
  bool foundewdk = false;

  if (!vns.GetVSInstanceAll(instances)) {
    return false;
  }
  for (const auto &i : instances) {
    if (i.IsEnterpriseWDK) {
      return true;
    }
  }
  vssetup::VSInstance vsi;
  if (EnterpriseWDK(root, vsi)) {
    instances.push_back(std::move(vsi));
    std::sort(instances.begin(), instances.end());
  }
  return true;
}
