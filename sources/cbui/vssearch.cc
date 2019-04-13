//////////
#include "inc/vssearch.hpp"
#include "inc/json.hpp"
#include "inc/comutils.hpp"
#include "inc/vssetup.hpp"
#include <cstdlib>
#include <cstdio>
#include <cctype>

std::wstring FsVisualStudioVersion(std::wstring_view vsdir) {
  auto vsfile = base::StringCat(vsdir, L"\\Version.txt");
  std::wstring ver;
  if (!clangbuilder::LookupVersionFromFile(vsfile, ver)) {
    return L"";
  }
  constexpr const std::wstring_view prefix = L"Visual Studio ";
  auto vp = base::StripPrefix(ver, prefix);
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
  auto findstr = base::StringCat(dir, L"\\*");
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
  auto ej = base::StringCat(root, L"\\config\\ewdk.json");
  if (!PathFileExistsW(ej.data())) {
    ej = base::StringCat(root, L"\\config\\ewdk.template.json");
    if (!PathFileExistsW(ej.data())) {
      return false;
    }
  }
  try {
    clangbuilder::FD fd;
    if (_wfopen_s(&fd.fd, ej.data(), L"rb") != 0) {
      return false;
    }
    auto j = nlohmann::json::parse(fd.P());
    auto path = j["Path"].get<std::string>();
    auto ewdkdir = base::ToWide(path);
    auto vsdir =
        base::StringCat(ewdkdir, L"\\Program Files\\Microsoft Visual Studio");
    auto product = FsUniqueSubdirName(vsdir);
    vsi.VSInstallLocation =
        base::StringCat(vsdir, L"\\", product, L"\\BuildTools");
    vsi.Version = FsVisualStudioVersion(vsi.VSInstallLocation);
    auto incdir =
        base::StringCat(ewdkdir, L"\\Program Files\\Windows Kits\\10\\include");
    auto sdkver = FsUniqueSubdirName(incdir);
    vsi.DisplayName = base::StringCat(L"Visual Studio BuildTools ", product,
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
