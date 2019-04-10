///////
#ifndef CBUI_APPHELP_HPP
#define CBUI_APPHELP_HPP
#include "base.hpp"
#include <Shlwapi.h>
#include <Shellapi.h>
#include <Shlobj.h>

namespace clangbuilder {

#if defined(_M_AMD64) || defined(_M_ARM64)
//#if defined(_X86_)
inline bool IsWow64ProcessEx() { return false; } /// constexpr
inline bool IsWow64Process() { return false; }   /// constexpr
class FsRedirection {};
#else
//// Windows x86 or other

/*
The GetModuleHandle function returns a handle to a mapped module without
incrementing its reference count. However, if this handle is passed to the
FreeLibrary function, the reference count of the mapped module will be
decremented. Therefore, do not pass a handle returned by GetModuleHandle to the
FreeLibrary function. Doing so can cause a DLL module to be unmapped
prematurely.
*/

class FsRedirection {
public:
  typedef BOOL WINAPI fntype_Wow64DisableWow64FsRedirection(PVOID *OldValue);
  typedef BOOL WINAPI fntype_Wow64RevertWow64FsRedirection(PVOID *OldValue);
  FsRedirection() {
    auto hmod = GetModuleHandleW(L"kernal32.dll");
    auto pfnWow64DisableWow64FsRedirection =
        (fntype_Wow64DisableWow64FsRedirection *)GetProcAddress(
            hmod, "Wow64DisableWow64FsRedirection");
    if (pfnWow64DisableWow64FsRedirection) {
      pfnWow64DisableWow64FsRedirection(&OldValue);
    }
  }
  ~FsRedirection() {
    auto hmod = GetModuleHandleW(L"kernal32.dll");
    auto pfnWow64RevertWow64FsRedirection =
        (fntype_Wow64RevertWow64FsRedirection *)GetProcAddress(
            hmod, "Wow64RevertWow64FsRedirection");
    if (pfnWow64RevertWow64FsRedirection) {
      pfnWow64RevertWow64FsRedirection(&OldValue);
    }
  }

private:
  PVOID OldValue = NULL;
};
typedef BOOL(WINAPI *LPFN_ISWOW64PROCESS)(HANDLE, PBOOL);
typedef BOOL(WINAPI *LPFN_ISWOW64PROCESS2)(HANDLE, PUSHORT, PUSHORT);

inline bool IsWow64ProcessEx() {
  auto hmod = GetModuleHandleW(L"kernal32.dll");
  if (hmod == nullptr) {
    return false;
  }
  auto fn = (LPFN_ISWOW64PROCESS2)GetProcAddress(hmod, "IsWow64Process2");
  if (fn == nullptr) {
    return false;
  }
  USHORT pm, nm;
  if (fn(GetCurrentProcess(), &pm, &nm) != TRUE) {
    return false;
  }
  return pm != nm;
}

inline bool IsWow64Process() {
  auto hmod = GetModuleHandleW(L"kernal32.dll");
  if (hmod == nullptr) {
    return false;
  }
  auto fn = (LPFN_ISWOW64PROCESS)GetProcAddress(hmod, "IsWow64Process");
  if (fn == nullptr) {
    return false;
  }
  BOOL bIsWow64 = FALSE;
  if (fn(GetCurrentProcess(), &bIsWow64) != TRUE) {
    return false;
  }
  return (bIsWow64 == TRUE);
}
#endif

constexpr size_t pathcchmax = 0x8000;
inline bool LookupClangbuilderTarget(std::wstring &root,
                                     std::wstring &targetFile,
                                     base::error_code &ec) {

  std::wstring engine_(pathcchmax, L'\0');
  auto buffer = &engine_[0];
  // std::array<wchar_t, PATHCCH_MAX_CCH> engine_;
  GetModuleFileNameW(nullptr, buffer, pathcchmax);
  std::wstring tmpfile;
  for (int i = 0; i < 5; i++) {
    if (!PathRemoveFileSpecW(buffer)) {
      return false;
    }
    tmpfile.assign(buffer);
    tmpfile.append(L"\\bin\\").append(L"ClangbuilderTarget.ps1");
    if (PathFileExistsW(tmpfile.c_str())) {
      root.assign(buffer);
      targetFile.assign(std::move(tmpfile));
      return true;
    }
  }
  ec = base::make_error_code(L"ClangbuilderTarget.ps1 not found");
  return false;
}

inline std::wstring ExpandEnv(std::wstring_view v) {
  std::wstring rstr(pathcchmax, L'\0');
  auto N = ExpandEnvironmentStringsW(v.data(), &rstr[0], pathcchmax);
  if (N >= 0) {
    rstr.resize(N - 1);
  } else {
    rstr.clear();
  }
  return rstr;
}

inline bool LookupPwshCore(std::wstring &ps) {
  bool success = false;
  auto psdir = ExpandEnv(L"%ProgramFiles%\\Powershell");
  if (!PathFileExistsW(psdir.c_str())) {
    psdir = ExpandEnv(L"%ProgramW6432%\\Powershell");
    if (!PathFileExistsW(psdir.c_str())) {
      return false;
    }
  }
  WIN32_FIND_DATAW wfd;
  auto findstr = base::strcat(psdir, L"\\*");
  HANDLE hFind = FindFirstFileW(findstr.c_str(), &wfd);
  if (hFind == INVALID_HANDLE_VALUE) {
    return false; /// Not found
  }
  do {
    if (wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
      auto pscore = base::strcat(psdir, L"\\", wfd.cFileName, L"\\pwsh.exe");
      if (PathFileExistsW(pscore.c_str())) {
        ps.assign(std::move(pscore));
        success = true;
        break;
      }
    }
  } while (FindNextFileW(hFind, &wfd));
  FindClose(hFind);
  return success;
}

inline bool IsPwshCoreEnable(std::wstring_view root, std::wstring &cmd) {
  auto rp = base::strcat(root, L"\\bin\\required_pwsh");
  if (!PathFileExistsW(rp.c_str())) {
    return false;
  }
  return LookupPwshCore(cmd);
}

inline bool LookupPwshDesktop(std::wstring &ps) {
  WCHAR pszPath[MAX_PATH]; /// by default , System Dir Length <260
  if (SHGetFolderPathW(nullptr, CSIDL_SYSTEM, nullptr, 0, pszPath) != S_OK) {
    return false;
  }
  ps = base::strcat(pszPath, L"\\WindowsPowerShell\\v1.0\\powershell.exe");
  return true;
}

} // namespace clangbuilder

#endif