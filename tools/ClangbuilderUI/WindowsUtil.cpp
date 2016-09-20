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
BOOL IsRunOnWin64()
{
	BOOL bIsWow64 = FALSE;
	LPFN_ISWOW64PROCESS fnIsWow64Process = (LPFN_ISWOW64PROCESS)GetProcAddress(
		GetModuleHandleW(L"kernel32"), "IsWow64Process");
	if (NULL != fnIsWow64Process) {
		if (!fnIsWow64Process(GetCurrentProcess(), &bIsWow64)) {
			// handle error
		}
	}
	//IsWow64Process
	return bIsWow64;
}