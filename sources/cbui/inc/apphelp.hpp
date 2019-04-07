///////
#ifndef CBUI_APPHELP_HPP
#define CBUI_APPHELP_HPP
#include "base.hpp"
#include <shlwapi.h>


namespace clangbuilder {
  
#if defined(_M_AMD64) || defined(_M_ARM64)
inline bool IsWow64ProcessEx() { return false; } /// constexpr
inline bool IsWow64Process() { return false; }   /// constexpr
class FsRedirection {};
#else
//// Windows x86 or other
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

/*
bool MainWindow::InitializeClangbuilderTarget() {
  std::wstring engine_(PATHCCH_MAX_CCH, L'\0');
  auto buffer = &engine_[0];
  // std::array<wchar_t, PATHCCH_MAX_CCH> engine_;
  GetModuleFileNameW(HINST_THISCOMPONENT, buffer, PATHCCH_MAX_CCH);
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
  return false;
}

*/

inline bool LookupClangbuilderTarget(std::wstring &root,
                                     std::wstring &targetFile,
                                     base::error_code &ec) {
  constexpr size_t pathcchmax = 0x8000;
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

} // namespace clangbuilder

#endif