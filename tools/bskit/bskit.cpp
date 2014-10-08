//////
#include <windows.h>
#include <stdio.h>
#include <tchar.h>
#pragma comment(lib,"Kernel32.lib")
typedef BOOL (WINAPI *LPFN_ISWOW64PROCESS) (HANDLE, PBOOL);

LPFN_ISWOW64PROCESS fnIsWow64Process;


BOOL IsRunOnWin64(){
   BOOL bIsWow64 = FALSE;
   fnIsWow64Process = (LPFN_ISWOW64PROCESS) GetProcAddress(
        GetModuleHandle(TEXT("kernel32")),"IsWow64Process");

    if(NULL != fnIsWow64Process)
    {
        if (!fnIsWow64Process(GetCurrentProcess(),&bIsWow64))
        {
            //handle error
        }
    }
    return bIsWow64;
}

///GetNativeSystemInfo Windows Phone 8/8.1 support
int RunNativeBITShell()
{
   SYSTEM_INFO si;
   GetNativeSystemInfo(&si);
}

int wmain()
{
      if(IsRunOnWin64())
        _tprintf(TEXT("The process is running under WOW64.\n"));
    else
        _tprintf(TEXT("The process is not running under WOW64.\n"));

    return 0;
}











