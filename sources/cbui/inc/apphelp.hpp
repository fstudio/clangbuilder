///////
#ifndef CBUI_APPHELP_HPP
#define CBUI_APPHELP_HPP
#include "base.hpp"

namespace help {

#if defined(_M_AMD64) || defined(_M_ARM64)
inline bool IsWow64ProcessEx() { return false; } /// constexpr
inline bool IsWow64Process() { return false; }   /// constexpr
#else
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

} // namespace help

#endif