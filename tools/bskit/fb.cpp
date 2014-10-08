#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UINCODE
#endif

#include <Windows.h>
#include <stdio.h>
#include <string>
#include <Shellapi.h>
#include <commctrl.h>
#include <tchar.h>
#include <strsafe.h>
#include <wchar.h>
#include <processthreadsapi.h>
#include <Shlobj.h>

#pragma comment(lib,"Shell32.lib")
#pragma comment(lib,"User32.lib")


int wmain()
{
   std::wstring posh;
   WCHAR wszPath[MAX_PATH];
   if(SHGetFolderPathW(NULL, 
                             CSIDL_SYSTEM, 
                             NULL, 
                             0, 
                             wszPath)!=S_OK)
							 {
							    return 4;
							 }
   posh+=wszPath;
   posh+=L"\\WindowsPowerShell\\v1.0\\powershell.exe";
   wprintf(posh.c_str());
   PROCESS_INFORMATION pi;
   STARTUPINFO si;
   ZeroMemory(&si, sizeof(si));
   si.cb = sizeof(si);
   si.dwFlags = STARTF_USESHOWWINDOW;
   si.wShowWindow = SW_SHOW;
   std::wstring argwstr=L"-NoLogo -NoExit   -File \"F:\\ClangSetup\\ClangSetupvNext\\tools\\Install.ps1\""; 
    wchar_t zsarg[32767]={0};
    argwstr.copy(zsarg,argwstr.length(),0);
	//wsprintf(zs,L"%1\0",argwstr.c_str());
	wprintf(zsarg);
    DWORD result = CreateProcessW(posh.c_str(), zsarg, NULL, NULL, NULL, CREATE_NEW_CONSOLE|NORMAL_PRIORITY_CLASS, NULL, NULL, &si, &pi);
   if(result==TRUE)
   {

     printf("\nSuccess");
   }else{
   printf("Error");
   }

  return 0;
}