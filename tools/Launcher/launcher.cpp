/////
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
#include "resource.h"
#ifndef ASSERT
#	ifdef _DEBUG
#		include <assert.h>
#		define ASSERT(x) assert( x )
#		define ASSERT_HERE assert( FALSE )
#	else// _DEBUG
#		define ASSERT(x) 
#	endif//_DEBUG
#endif//ASSERT

///////////////////////////////////////////////////////////////////
// a handy macro to get the number of characters (not bytes!) 
// a string buffer can hold

#ifndef _tsizeof 
#	define _tsizeof( s )  (sizeof(s)/sizeof(s[0]))
#endif//_tsizeof

#include <comdef.h>
#include <taskschd.h>

#define MAX_UNC_PATH (32*1024-1)

int Launcher(std::wstring wstr);
int OutErrorMessage(const wchar_t* errorMsg,const wchar_t* errorTitle);





HRESULT CALLBACK
TaskDialogCallbackProc(
__in HWND hwnd,
__in UINT msg,
__in WPARAM wParam,
__in LPARAM lParam,
__in LONG_PTR lpRefData
)
{
    UNREFERENCED_PARAMETER(lpRefData);
	UNREFERENCED_PARAMETER(wParam);
	switch (msg)
	{
	case TDN_CREATED:
		::SetForegroundWindow(hwnd);
		break;
	case TDN_RADIO_BUTTON_CLICKED:
		break;
	case TDN_BUTTON_CLICKED:
		break;
	case TDN_HYPERLINK_CLICKED:
		ShellExecute(hwnd, NULL, (LPCTSTR)lParam, NULL, NULL, SW_SHOWNORMAL);
		break;
	}

	return S_OK;
}

LRESULT WINAPI CreateTaskDialogIndirectFd(
	__in HWND		hwndParent,
	__in HINSTANCE	hInstance,
	__out_opt int *	pnButton,
	__out_opt int *	pnRadioButton
	)
{
	TASKDIALOGCONFIG tdConfig;
	//BOOL bElevated = FALSE;
	memset(&tdConfig, 0, sizeof(tdConfig));
	
	const wchar_t usageInfo[]=L"ClangSetup Native Launcher\n\
Usage:\nLauncher [-V value] [-T value] [-B value] [-R value] [-M value] [-C]\r\n\
-V         VisualStudio: VS110|VS120|VS140|VS150\n\
-T         Target: X86|X64|ARM|AArch64\n\
-B         Build: Release|MinSizeRel|RelWithDebInfo|Debug\n\
-R         Link Runtime: MT(d)|MD(d)\n\
-M        Make Install Package: MKI|NMKI\n\
-C         Use Clean Environment\n\
Example:\n\
          Launcher -V VS110 -T X64 -B MinSizeRel -R MT -M MKI -E \r\n\n\
ClangSetup Native Lanucher 1.0\n\
Copyright \xA9 2015 ForceStudio.All Right Reserved.";
 
	tdConfig.cbSize = sizeof(tdConfig);

	tdConfig.hwndParent = hwndParent;
	tdConfig.hInstance = hInstance;
	tdConfig.dwFlags =
		TDF_ALLOW_DIALOG_CANCELLATION |
		TDF_EXPAND_FOOTER_AREA |
		TDF_POSITION_RELATIVE_TO_WINDOW |
		TDF_SIZE_TO_CONTENT|
		TDF_ENABLE_HYPERLINKS;


	tdConfig.nDefaultRadioButton = *pnRadioButton;

	tdConfig.pszWindowTitle = L"ClangSetup Native Launcher";

	tdConfig.pszMainInstruction = _T("ClangSetup Native Launcher Usage");

	tdConfig.hMainIcon = static_cast<HICON>(LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_ICON_LAUNCHER)));
	tdConfig.dwFlags |= TDF_USE_HICON_MAIN;


	tdConfig.pszContent = usageInfo;
	tdConfig.cxWidth=270;
	tdConfig.pszExpandedInformation = _T("For more information about this tool, ")
		_T("Visit: <a href=\"https://github.com/forcegroup\">Force\xAEStudio</a>");

	tdConfig.pszCollapsedControlText = _T("More information");
	tdConfig.pszExpandedControlText = _T("Less information");
	tdConfig.pfCallback = TaskDialogCallbackProc;

	HRESULT hr = TaskDialogIndirect(&tdConfig, pnButton, pnRadioButton, NULL);

	return hr;
}


void Usage()
{
	int	nButton = 0;
	int nRadioButton = 0;
	CreateTaskDialogIndirectFd(nullptr, GetModuleHandle(nullptr), &nButton, &nRadioButton);
}


int LauncherInit()
{
   if(__argc<11)
   {
    Usage();
	return 1;
   }
   std::wstring psargs;
   if((wcscmp(__wargv[1],L"-V")==0)&&(wcscmp(__wargv[3],L"-T")==0)&&(wcscmp(__wargv[5],L"-B")==0)&&(wcscmp(__wargv[7],L"-R")==0)&&(wcscmp(__wargv[9],L"-M")==0))
   {
     for(int i=1;i<=5;i++)
	 {
	    psargs+=__wargv[i*2];
		psargs+=L" ";
	 }
   }else{
   Usage();
    return 2;
   }
   if(__argc==12&&(wcscmp(__wargv[11],L"-C")==0))
   {
    psargs+=L"-UseCleanEnv";
   }
   //MessageBoxW(nullptr,psargs.c_str(),L"LANUCHERDEBUG",MB_OK);
   //Usage();
   return Launcher(psargs);
}


int WINAPI wWinMain(HINSTANCE hInstance,HINSTANCE hPrevInstance,LPWSTR lpCmdLine,int nCmdShow)
{
	UNREFERENCED_PARAMETER(hInstance);
	UNREFERENCED_PARAMETER(hPrevInstance);
	UNREFERENCED_PARAMETER(lpCmdLine);
	UNREFERENCED_PARAMETER(nCmdShow);
	int Ret=0;
	Ret=LauncherInit();
	return Ret;
}

int Launcher(std::wstring wstr)
{
   std::wstring csbuilder;
   wchar_t apppath[MAX_UNC_PATH];
   GetModuleFileNameW(nullptr,apppath,MAX_UNC_PATH);
   std::wstring appwstr=apppath;
   std::wstring::size_type np=appwstr.rfind(L"\\");
   if(np!=std::wstring::npos){
   csbuilder=appwstr.substr(0,np);
   std::wstring::size_type  npx=csbuilder.rfind(L"\\",np);
     if(npx!=std::wstring::npos){
	 appwstr=csbuilder.substr(0,npx);
	 np=appwstr.rfind(L"\\");
	 if(np!=std::wstring::npos)
	 {
	    csbuilder=appwstr.substr(0,np);
	 }
   }
   }
   csbuilder+=L"\\ClangBuilderPSvNext.ps1";
   if(_waccess(csbuilder.c_str(),0)!=0)
   {
        OutErrorMessage(csbuilder.c_str(),L"File does not exist or cannot be accessed");
		return 3;
   }
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
   std::wstring argwstr=L"-NoLogo -NoExit   -File \"";
   argwstr+=csbuilder;
   argwstr+=L"\" "; 
   argwstr+=wstr;   
   wchar_t zsarg[32767]={0};
   argwstr.copy(zsarg,argwstr.length(),0);
	//wsprintf(zs,L"%1\0",argwstr.c_str());
	//MessageBoxW(nullptr,zsarg,L"ARGS",MB_OK);
    DWORD result = CreateProcessW(posh.c_str(), zsarg, NULL, NULL, NULL, CREATE_NEW_CONSOLE|NORMAL_PRIORITY_CLASS, NULL, NULL, &si, &pi);
   if(result!=TRUE)
   {
     return 5;
   }
   return 0;
}


int OutErrorMessage(const wchar_t* errorMsg,const wchar_t* errorTitle)
{
    int nButton = 0;
	int nRadioButton = 0;
	TASKDIALOGCONFIG tdConfig;
	memset(&tdConfig, 0, sizeof(tdConfig));
	tdConfig.cbSize = sizeof(tdConfig);
	tdConfig.hwndParent = nullptr;
	tdConfig.hInstance = GetModuleHandle(nullptr);
	tdConfig.dwFlags =
		TDF_ALLOW_DIALOG_CANCELLATION |
		TDF_EXPAND_FOOTER_AREA |
		TDF_POSITION_RELATIVE_TO_WINDOW |
		TDF_SIZE_TO_CONTENT|
		TDF_ENABLE_HYPERLINKS;


	tdConfig.nDefaultRadioButton = nRadioButton;

	tdConfig.pszWindowTitle = L"ClangSetup Launcher Error";

	tdConfig.pszMainInstruction =errorTitle;

	tdConfig.hMainIcon = static_cast<HICON>(LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_ICON_LAUNCHER)));
	tdConfig.dwFlags |= TDF_USE_HICON_MAIN;


	tdConfig.pszContent = errorMsg;
	tdConfig.pszExpandedInformation = _T("For more information about this tool, ")
		_T("Visit: <a href=\"https://github.com/forcegroup\">Force\xAEStudio</a>");

	tdConfig.pszCollapsedControlText = _T("More information");
	tdConfig.pszExpandedControlText = _T("Less information");
	tdConfig.pfCallback = TaskDialogCallbackProc;

 HRESULT hr = TaskDialogIndirect(&tdConfig, &nButton, &nRadioButton, NULL);
 return hr;
}



