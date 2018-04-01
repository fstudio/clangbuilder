#include "stdafx.h"

/*
WINBASEAPI
BOOL
WINAPI
IsWow64Process2(
_In_ HANDLE hProcess,
_Out_ USHORT * pProcessMachine,
_Out_opt_ USHORT * pNativeMachine
);
*/

typedef BOOL(WINAPI *LPFN_ISWOW64PROCESS)(HANDLE, PBOOL);
typedef BOOL(WINAPI *LPFN_ISWOW64PROCESS2)(HANDLE, PUSHORT, PUSHORT);

HMODULE KrModule() {
  static HMODULE hModule = GetModuleHandleW(L"kernel32.dll");
  if (hModule == nullptr) {
    OutputDebugStringW(L"GetModuleHandleA failed");
  }
  return hModule;
}

BOOL KrIsWow64Process() {
#ifndef _M_IX86
  return FALSE;
#else
  BOOL bIsWow64 = FALSE;
  auto hModule = KrModule();
  if (hModule == nullptr)
    return FALSE;
  LPFN_ISWOW64PROCESS fnIsWow64Process =
      (LPFN_ISWOW64PROCESS)GetProcAddress(hModule, "IsWow64Process");
  if (nullptr != fnIsWow64Process) {
    if (!fnIsWow64Process(GetCurrentProcess(), &bIsWow64)) {
      // handle error
    }
  }
  // IsWow64Process
  return bIsWow64;
#endif
}

BOOL KrIsWow64ProcessEx() {
#if defined(_M_AMD64) || defined(_M_ARM64)
  return FALSE;
#else
  auto hModule = KrModule();
  if (hModule == nullptr)
    return FALSE;
  LPFN_ISWOW64PROCESS2 fnIsWow64Process2 =
      (LPFN_ISWOW64PROCESS2)GetProcAddress(hModule, "IsWow64Process2");
  if (fnIsWow64Process2 == nullptr) {
    return FALSE;
  }
  USHORT pm, nm;
  if (fnIsWow64Process2(GetCurrentProcess(), &pm, &nm) != TRUE) {
    return FALSE;
  }
  if (pm != nm)
    return TRUE;
  return FALSE;
#endif
}
