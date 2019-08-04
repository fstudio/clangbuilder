///////
#ifndef CLANGBUILDER_FS_HPP
#define CLANGBUILDER_FS_HPP
#include <bela/base.hpp>
#include <bela/env.hpp>

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

inline bool PathExists(std::wstring_view p) {
  auto dwAttr = GetFileAttributesW(p.data());
  return dwAttr != INVALID_FILE_ATTRIBUTES;
}

inline bool PathAbsolute(std::wstring &dest, std::wstring_view src) {
  if (src.empty()) {
    return false;
  }
  std::wstring buffer;
  auto L = GetFullPathNameW(src.data(), 0, nullptr, nullptr);
  if (L <= 0) {
    return false;
  }
  buffer.resize(L + 1);
  L = GetFullPathNameW(src.data(), L + 1, buffer.data(), nullptr);
  buffer.resize(L);
  dest.assign(std::move(buffer));
  return true;
}

inline bool PathRemoveFileSpecU(wchar_t *lpszPath) {
  LPWSTR lpszFileSpec = lpszPath;
  bool bModified = false;

  if (lpszPath) {
    /* Skip directory or UNC path */
    if (*lpszPath == '\\')
      lpszFileSpec = ++lpszPath;
    if (*lpszPath == '\\')
      lpszFileSpec = ++lpszPath;

    while (*lpszPath) {
      if (*lpszPath == '\\')
        lpszFileSpec = lpszPath; /* Skip dir */
      else if (*lpszPath == ':') {
        lpszFileSpec = ++lpszPath; /* Skip drive */
        if (*lpszPath == '\\') {
          lpszFileSpec++;
        }
      }
      lpszPath++;
    }
    if (*lpszFileSpec) {
      *lpszFileSpec = '\0';
      bModified = true;
    }
  }
  return bModified;
}

inline bool LookupClangbuilderTarget(std::wstring &root,
                                     std::wstring &targetFile,
                                     bela::error_code &ec) {

  std::wstring engine_(pathcchmax, L'\0');
  auto buffer = &engine_[0];
  // std::array<wchar_t, PATHCCH_MAX_CCH> engine_;
  GetModuleFileNameW(nullptr, buffer, pathcchmax);
  for (int i = 0; i < 5; i++) {
    if (!PathRemoveFileSpecU(buffer)) {
      return false;
    }
    auto tmpfile = bela::StringCat(buffer, L"\\bin\\ClangbuilderTarget.ps1");
    if (PathExists(tmpfile)) {
      root.assign(buffer);
      targetFile.assign(std::move(tmpfile));
      return true;
    }
  }
  ec = bela::make_error_code(1, L"ClangbuilderTarget.ps1 not found");
  return false;
}

inline bool LookupPwshCore(std::wstring &ps) {
  bool success = false;
  auto psdir = bela::ExpandEnv(L"%ProgramFiles%\\Powershell");
  if (!PathExists(psdir)) {
    psdir = bela::ExpandEnv(L"%ProgramW6432%\\Powershell");
    if (!PathExists(psdir)) {
      return false;
    }
  }
  WIN32_FIND_DATAW wfd;
  auto findstr = bela::StringCat(psdir, L"\\*");
  HANDLE hFind = FindFirstFileW(findstr.c_str(), &wfd);
  if (hFind == INVALID_HANDLE_VALUE) {
    return false; /// Not found
  }
  do {
    if (wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
      auto pscore = bela::StringCat(psdir, L"\\", wfd.cFileName, L"\\pwsh.exe");
      if (PathExists(pscore)) {
        ps.assign(std::move(pscore));
        success = true;
        break;
      }
    }
  } while (FindNextFileW(hFind, &wfd));
  FindClose(hFind);
  return success;
}

inline bool LookupPwshDesktop(std::wstring &ps) {
  WCHAR pszPath[MAX_PATH]; /// by default , System Dir Length <260
  // https://docs.microsoft.com/en-us/windows/desktop/api/sysinfoapi/nf-sysinfoapi-getsystemdirectoryw
  auto N = GetSystemDirectoryW(pszPath, MAX_PATH);
  if (N == 0) {
    return false;
  }
  pszPath[N] = 0;
  ps = bela::StringCat(pszPath, L"\\WindowsPowerShell\\v1.0\\powershell.exe");
  return true;
}

} // namespace clangbuilder

#endif