//////////
#include <cstdlib>
#include <cstdio>
#include <cctype>
#include <vssetup.hpp>
#include <appfs.hpp>
#include "app.hpp"

std::wstring FsVisualStudioVersion(std::wstring_view vsdir) {
  auto vsfile = bela::StringCat(vsdir, L"\\Version.txt");
  std::wstring ver;
  if (!clangbuilder::LookupVersionFromFile(vsfile, ver)) {
    return L"";
  }
  constexpr const std::wstring_view prefix = L"Visual Studio ";
  auto vp = bela::StripPrefix(ver, prefix);
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
  WIN32_FIND_DATAW wfd;
  if (!dir.empty() && (dir.back() == L'\\' || dir.back() == L'/')) {
    dir.remove_suffix(1);
  }
  auto findstr = bela::StringCat(dir, L"\\*");
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

bool VisualStudioSeacher::EnterpriseWDK(std::wstring_view ewdkroot,
                                        clangbuilder::VSInstance &vsi) {
  if (ewdkroot.empty()) {
    return false;
  }
  auto vsdir =
      bela::StringCat(ewdkroot, L"\\Program Files\\Microsoft Visual Studio");
  if (!clangbuilder::PathExists(vsdir)) {
    return false;
  }
  auto product = FsUniqueSubdirName(vsdir);
  vsi.VSInstallLocation =
      bela::StringCat(vsdir, L"\\", product, L"\\BuildTools");
  vsi.Version = FsVisualStudioVersion(vsi.VSInstallLocation);
  auto incdir =
      bela::StringCat(ewdkroot, L"\\Program Files\\Windows Kits\\10\\include");
  auto sdkver = FsUniqueSubdirName(incdir);
  vsi.DisplayName = bela::StringCat(L"Visual Studio BuildTools ", product,
                                    L" (Enterprise WDK ", sdkver, L")");
  vsi.InstanceId.assign(L"VisualStudio.EWDK");
  return true;
}

bool VisualStudioSeacher::Execute(std::wstring_view root,
                                  std::wstring_view ewdkroot) {
  clangbuilder::VisualStudioNativeSearcher vns;

  if (!vns.GetVSInstanceAll(instances)) {
    return false;
  }
  for (const auto &i : instances) {
    if (i.IsEnterpriseWDK) {
      return true;
    }
  }
  clangbuilder::VSInstance vsi;
  if (EnterpriseWDK(ewdkroot, vsi)) {
    instances.push_back(std::move(vsi));
    std::sort(instances.begin(), instances.end());
  }
  return true;
}
