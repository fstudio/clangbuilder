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
#include <Shlwapi.h>
#include <sstream>
#include "resource.h"

#include "Arguments.hpp"
#include "CommandLineArgumentsEx.hpp"

#ifndef ASSERT
#ifdef _DEBUG
#include <assert.h>
#define ASSERT(x) assert( x )
#define ASSERT_HERE assert( FALSE )
#else// _DEBUG
#define ASSERT(x)
#endif//_DEBUG
#endif//ASSERT

///////////////////////////////////////////////////////////////////
// a handy macro to get the number of characters (not bytes!)
// a string buffer can hold

#ifndef _tsizeof
#define _tsizeof( s )  (sizeof(s)/sizeof(s[0]))
#endif//_tsizeof

#include <comdef.h>
#include <taskschd.h>

#define MAX_UNC_PATH (32*1024-1)

int Launcher(std::wstring wstr);
int OutErrorMessage(const wchar_t* errorMsg,const wchar_t* errorTitle);

const wchar_t usageInfo[]=L"ClangSetup Native Launcher\n\
Usage: [Option] value\r\n\
String Options:\n\
-V \tVisualStudio:  VS110|VS120|VS140|VS150\n\
-T\tTarget:  X86|X64|ARM|AArch64\n\
-B \tBuild:  Release|MinSizeRel|RelWithDebInfo|Debug\n\
Boolean Option:\n\
-MD\tLink Runtime: Link msvcrtXX.dll\n\
-MK \tMake Install Package:\n\
-CE\tUse Clean Environment\n\
-LLDB\tAdd Building LLDB\n\
-NMake\tUse NMake not MSBuild\n\
Example:\n\
Launcher -V VS110 -T X64 -B MinSizeRel  -MD -MK -CE -NMake \n\n\
Clangbuilder Native Lanucher 2.0\n\
Copyright \xA9 2015 Force Charlie.All Right Reserved.";


int cmdUnknownArgument(const wchar_t *args, void *data) {
    int nButtonPressed = 0;
    TaskDialog(NULL, GetModuleHandle(nullptr),
        L"Clangbuilder vNext Launcher",
        L"cmd Unknown Options: ",
        args,
        TDCBF_OK_BUTTON ,TD_ERROR_ICON,&nButtonPressed);
    auto p=static_cast<bool *>(data);
    *p=true;
    return 1;
}

void PrintVersion()
{
    int nButtonPressed = 0;
    TaskDialog(NULL, GetModuleHandle(nullptr),
        L"Clangbuilder vNext Launcher",
        L"Version Info: ",
        LAUNCHER_APP_VERSION,
        TDCBF_OK_BUTTON ,TD_INFORMATION_ICON,&nButtonPressed);
}


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
    tdConfig.cbSize = sizeof(tdConfig);
    tdConfig.hwndParent = hwndParent;
    tdConfig.hInstance = hInstance;
    tdConfig.dwFlags =TDF_ALLOW_DIALOG_CANCELLATION |TDF_EXPAND_FOOTER_AREA |
    TDF_POSITION_RELATIVE_TO_WINDOW |TDF_SIZE_TO_CONTENT|TDF_ENABLE_HYPERLINKS;
    tdConfig.nDefaultRadioButton = *pnRadioButton;
    tdConfig.pszWindowTitle = L"ClangSetup Native Launcher";
    tdConfig.pszMainInstruction = _T("ClangSetup Native Launcher Info");
    tdConfig.hMainIcon = static_cast<HICON>(LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_ICON_LAUNCHER)));
    tdConfig.dwFlags |= TDF_USE_HICON_MAIN;
    tdConfig.pszContent = L"Launcher Normal";
    tdConfig.cxWidth=270;
    tdConfig.pszExpandedInformation = _T("For more information about this tool, ")
    _T("Visit: <a href=\"http://forcemz.net/\">Force.Charlie</a>");
    tdConfig.pszCollapsedControlText = _T("More information");
    tdConfig.pszExpandedControlText = _T("Less information");
    tdConfig.pfCallback = TaskDialogCallbackProc;
    HRESULT hr = TaskDialogIndirect(&tdConfig, pnButton, pnRadioButton, NULL);
    return hr;
}


void Usage()
{
    MessageBoxW(nullptr,usageInfo,L"Clangbuilder vNext Launcher Help",MB_OK);
    int nButton = 0;
    int nRadioButton = 0;
    CreateTaskDialogIndirectFd(nullptr, GetModuleHandle(nullptr), &nButton, &nRadioButton);
}


int LauncherInit()
{
    Arguments arguments=Arguments::Main();
    int Argc=arguments.argc();
    wchar_t const  *const* Argv=arguments.argv();
    std::wstring vsv=L"VS120";
    std::wstring target=L"x64";
    std::wstring buildtype=L"Release";
    std::wstringstream argstream;
    bool bHelp=false;
    bool bVersion=false;
    bool bMtd=false;
    bool bMakePkg=false;
    bool bCleanEnv=false;
    bool bUseNmake=false;
    bool bLLDB=false;
    if(Argc==1)
    {
        Usage();
        return 0;
    }
   typedef Force::CommandLineArguments argT;
    Force::CommandLineArguments Args;
    Args.Initialize(Argc,Argv);
    Args.AddArgument(L"--help", argT::NO_ARGUMENT, &bHelp,
        L"Cmd Print Help");
    Args.AddArgument(L"--version", argT::NO_ARGUMENT, &bVersion,
        L"Print Phoenix version");
    Args.AddArgument(L"-V",argT::SPACE_ARGUMENT,&vsv,
        L"Select VisualStudio Version");
    Args.AddArgument(L"-T", argT::SPACE_ARGUMENT, &target,
        L"Select Build Target");
    Args.AddArgument(L"-B",argT::SPACE_ARGUMENT,&buildtype,
        L"Select Build Type,or Relase MinSizeRel Debug RelWithDebugInfo");
    Args.AddArgument(L"-MD",argT::NO_ARGUMENT,&bMtd,
        L"Use Multi DLL");
    Args.AddArgument(L"-MK",argT::NO_ARGUMENT,&bMakePkg,
        L"Create Install Package");
    Args.AddArgument(L"-CE",argT::NO_ARGUMENT,&bCleanEnv,
        L"Use Clean Environment");
    Args.AddArgument(L"-NMake",argT::NO_ARGUMENT,&bUseNmake,
        L"Use NMake Build,Not MSBuild");
    Args.AddArgument(L"-LLDB",argT::NO_ARGUMENT,&bLLDB,
        L"Add Building LLDB");
    Args.SetUnknownArgumentCallback(cmdUnknownArgument);
    bool ishaveUnknown=false;
    Args.SetClientData(&ishaveUnknown);
    int parsed=Args.Parse();
    if(!parsed)
        return -1;
    if(ishaveUnknown)
        return 1;
    if(bHelp)
    {
        Usage();
        return 0;
    }else if(bVersion)
    {
        PrintVersion();
        return 0;
    }
	argstream << vsv << L" " << target << L" " << buildtype << (bMtd ? L" MD" : L" MT") << (bMakePkg ? L" MKI" : L" NOMKI") << (bCleanEnv ? L" -E" : L" -Ne")
		<< (bUseNmake ? L" -NMake" : L" -MSBuild");
	if(bLLDB )
		argstream<<L" -LLDB";
    //MessageBoxW(nullptr,argstream.str().c_str(),L"Args",MB_OK);
    //return 0;
    return Launcher(argstream.str());
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
        if(np!=std::wstring::npos){
            csbuilder=appwstr.substr(0,np);
        }
    }
    }
   csbuilder+=L"\\ClangBuilderPSvNext.ps1";
   if(!PathFileExistsW(csbuilder.c_str()))
   {
    OutErrorMessage(csbuilder.c_str(),L"File does not exist or cannot be accessed");
    return 3;
   }
   std::wstring posh;
   WCHAR wszPath[MAX_PATH];
   if(SHGetFolderPathW(NULL,CSIDL_SYSTEM,NULL,0,wszPath)!=S_OK){
    return 4;
   }
   posh+=wszPath;
   posh+=L"\\WindowsPowerShell\\v1.0\\powershell.exe";
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
   wchar_t* zsarg=nullptr;
   zsarg=_wcsdup(argwstr.c_str());
    DWORD result = CreateProcessW(posh.c_str(), zsarg, NULL, NULL, NULL, CREATE_NEW_CONSOLE|NORMAL_PRIORITY_CLASS, NULL, NULL, &si, &pi);
    free(zsarg);
   return result?0:5;
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
    tdConfig.dwFlags =TDF_ALLOW_DIALOG_CANCELLATION |TDF_EXPAND_FOOTER_AREA |
    TDF_POSITION_RELATIVE_TO_WINDOW |TDF_SIZE_TO_CONTENT|TDF_ENABLE_HYPERLINKS;
    tdConfig.nDefaultRadioButton = nRadioButton;
    tdConfig.pszWindowTitle = L"Clangbuilder Launcher Error";
    tdConfig.pszMainInstruction =errorTitle;
    tdConfig.hMainIcon = static_cast<HICON>(LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_ICON_LAUNCHER)));
    tdConfig.dwFlags |= TDF_USE_HICON_MAIN;
    tdConfig.pszContent = errorMsg;
    tdConfig.pszExpandedInformation = _T("For more information about this tool, ")
		_T("Visit: <a href=\"https://github.com/fstudio\">Force Charlie</a>");
    tdConfig.pszCollapsedControlText = _T("More information");
    tdConfig.pszExpandedControlText = _T("Less information");
    tdConfig.pfCallback = TaskDialogCallbackProc;
    HRESULT hr = TaskDialogIndirect(&tdConfig, &nButton, &nRadioButton, NULL);
    return hr;
}



