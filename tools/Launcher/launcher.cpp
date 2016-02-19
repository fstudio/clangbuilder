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
#include "GetOptInc.h"

#ifndef ASSERT
#ifdef _DEBUG
#include <assert.h>
#define ASSERT(x) assert(x)
#define ASSERT_HERE assert(FALSE)
#else // _DEBUG
#define ASSERT(x)
#endif //_DEBUG
#endif // ASSERT

#ifndef _tsizeof
#define _tsizeof(s) (sizeof(s) / sizeof(s[0]))
#endif //_tsizeof

#include <comdef.h>
#include <taskschd.h>

#define UNC_MAX_PATH (32 * 1024 - 1)

int OutErrorMessage(const wchar_t *errorMsg, const wchar_t *errorTitle);

int cmdUnknownArgument(const wchar_t *args, void *data) {
  int nButtonPressed = 0;
  TaskDialog(NULL, GetModuleHandle(nullptr), L"Clangbuilder vNext Launcher",
             L"cmd Unknown Options: ", args, TDCBF_OK_BUTTON, TD_ERROR_ICON,
             &nButtonPressed);
  auto p = static_cast<bool *>(data);
  *p = true;
  return 1;
}

void PrintVersion() {
  int nButtonPressed = 0;
  TaskDialog(NULL, GetModuleHandle(nullptr), L"Clangbuilder  Launcher",
             L"Version Info: ", LAUNCHER_APP_VERSION, TDCBF_OK_BUTTON,
             TD_INFORMATION_ICON, &nButtonPressed);
}

HRESULT CALLBACK TaskDialogCallbackProc(__in HWND hwnd, __in UINT msg,
                                        __in WPARAM wParam, __in LPARAM lParam,
                                        __in LONG_PTR lpRefData) {
  UNREFERENCED_PARAMETER(lpRefData);
  UNREFERENCED_PARAMETER(wParam);
  switch (msg) {
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

LRESULT WINAPI AboutMessageShow(__in HWND hwndParent, __in HINSTANCE hInstance,
                                __out_opt int *pnButton,
                                __out_opt int *pnRadioButton) {
  TASKDIALOGCONFIG tdConfig;
  // BOOL bElevated = FALSE;
  memset(&tdConfig, 0, sizeof(tdConfig));
  tdConfig.cbSize = sizeof(tdConfig);
  tdConfig.hwndParent = hwndParent;
  tdConfig.hInstance = hInstance;
  tdConfig.dwFlags = TDF_ALLOW_DIALOG_CANCELLATION | TDF_EXPAND_FOOTER_AREA |
                     TDF_POSITION_RELATIVE_TO_WINDOW | TDF_SIZE_TO_CONTENT |
                     TDF_ENABLE_HYPERLINKS;
  tdConfig.nDefaultRadioButton = *pnRadioButton;
  tdConfig.pszWindowTitle = L"Clangbuilder Launcher";
  tdConfig.pszMainInstruction = _T("Clangbuilder Launcher Info");
  tdConfig.hMainIcon = static_cast<HICON>(
      LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_ICON_LAUNCHER)));
  tdConfig.dwFlags |= TDF_USE_HICON_MAIN;
  tdConfig.pszContent = L"Launcher Normal";
  tdConfig.cxWidth = 270;
  tdConfig.pszExpandedInformation =
      _T("For more information about this tool, ")
      _T("Visit: <a href=\"http://forcemz.net/\">Force.Charlie</a>");
  tdConfig.pszCollapsedControlText = _T("More information");
  tdConfig.pszExpandedControlText = _T("Less information");
  tdConfig.pfCallback = TaskDialogCallbackProc;
  HRESULT hr = TaskDialogIndirect(&tdConfig, pnButton, pnRadioButton, NULL);
  return hr;
}

const wchar_t usageInfo[] =
    L"OVERVIEW: Clangbuilder launcher utility\n"
    L"\nOPTIONS:\n"
    L"Usage: launcher [options| V:A:F:BEICRSLNH ] <input>\n"
    L"  -V\t[--vs] Visual Studio version \n\tAllow:  110| 120| 140| 141| "
    L"150\n\n"
    L"  -A\t[--arch] LLVM Arch \n\tAllow: x86| x64| ARM| ARM64\n\n"
    L"  -F\t[--flavor] Flavor \n\tAllow: Debug| Release| MinSizeRel| "
    L"RelWithDebInfo\n\n"
    L"  -B\t[--bootstrap] Bootstrap llvm\n"
    L"  -E\t[--env] Startup Environment not run builder\n"
    L"  -I\t[--install] Create Install Package\n"
    L"  -C\t[--clear] Clear Environment\n"
    L"  -R\t[--released] Build Last Released Revision\n"
    L"  -S\t[--static] Use Static C Runtime Library\n"
    L"  -L\t[--lldb] Build LLDB\n"
    L"  -N\t[--nmake] nmake\n"
    L"  -H\t[--help] Print Help Message";

void Usage() {
  MessageBoxW(nullptr, usageInfo, L"Clangbuilder Launcher Help", MB_OK);
  int nButton = 0;
  int nRadioButton = 0;
  AboutMessageShow(nullptr, GetModuleHandle(nullptr), &nButton, &nRadioButton);
}

enum ClangBuilderChannel : int {
  kOpenEnvironment = 0, ///
  kUseMSBuild = 1,
  kNinjaBootstrap
};

int LauncherStartup(const wchar_t *args, int channel) {
  wchar_t pwszPath[UNC_MAX_PATH];
  GetModuleFileNameW(nullptr, pwszPath, UNC_MAX_PATH);
  PathRemoveFileSpecW(pwszPath);
  PathRemoveFileSpecW(pwszPath);
  PathRemoveFileSpecW(pwszPath);
  std::wstring psfile = pwszPath;
  switch (channel) {
  case kOpenEnvironment:
    psfile += L"\\bin\\ClangBuilderEnvironment.ps1";
    break;
  case kUseMSBuild:
    psfile += L"\\bin\\ClangBuilderManager.ps1";
    break;
  case kNinjaBootstrap:
    psfile += L"\\bin\\ClangBuilderBootstrap.ps1";
    break;
  default: {
    std::wstring msg =
        L"Not support channel value: " + std::to_wstring(channel);
    OutErrorMessage(msg.c_str(), L"Not support clangbuilder channel !");
    return -2;
  }
  }
  if (!PathFileExistsW(psfile.c_str())) {
    OutErrorMessage(psfile.c_str(), L"PathFileExists return false");
    // OutErrorMessage(args, L"Show Args");
    return -1;
  }

  if (SHGetFolderPathW(NULL, CSIDL_SYSTEM, NULL, 0, pwszPath) != S_OK) {
    return -1;
  }
  auto length = wcslen(pwszPath);
  StringCchCatW(pwszPath, UNC_MAX_PATH - length,
                L"\\WindowsPowerShell\\v1.0\\powershell.exe ");
  length = wcslen(pwszPath);
  auto offsetPtr = pwszPath + length;
  StringCchPrintfW(offsetPtr, UNC_MAX_PATH - length,
                   L" -NoLogo -NoExit   -File \"%s\" %s", psfile.c_str(), args);
  PROCESS_INFORMATION pi;
  STARTUPINFO si;
  ZeroMemory(&si, sizeof(si));
  ZeroMemory(&pi, sizeof(pi));
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESHOWWINDOW;
  si.wShowWindow = SW_SHOW;
  if (CreateProcessW(nullptr, pwszPath, NULL, NULL, FALSE,
                     CREATE_NEW_CONSOLE | NORMAL_PRIORITY_CLASS, NULL, NULL,
                     &si, &pi)) {
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return 0;
  }
  return GetLastError();
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                    LPWSTR lpCmdLine, int nCmdShow) {
  UNREFERENCED_PARAMETER(hInstance);
  UNREFERENCED_PARAMETER(hPrevInstance);
  UNREFERENCED_PARAMETER(lpCmdLine);
  UNREFERENCED_PARAMETER(nCmdShow);
  const wchar_t *vs = L"120";
  const wchar_t *target = L"x64";
  const wchar_t *flavor = L"Release";
  bool createInstallPkg = false;
  bool clearEnv = false;
  bool useNmake = false;
  bool buildReleasedRevision = false;
  bool useStaticCRT = false;
  bool buildLLDB = false;
  int channel = kUseMSBuild;
  int Argc = 0;
  auto Argv_ = CommandLineToArgvW(GetCommandLineW(), &Argc);
  wchar_t *const *Argv = Argv_;
  int ch;
  const wchar_t *short_opts = L"V:A:F:BEICRSLNH"; // L"V:T:C:BIERSLNH";
  const option option_long_opt[] = {
      ///
      {L"vs", required_argument, NULL, 'V'},
      {L"arch", required_argument, NULL, 'A'},
      {L"flavor", required_argument, NULL, 'F'},
      {L"bootstrap", no_argument, NULL, 'B'},
      {L"env", no_argument, NULL, 'E'},
      {L"install", no_argument, NULL, 'I'},
      {L"clear", no_argument, NULL, 'C'},
      {L"released", no_argument, NULL, 'R'},
      {L"static", no_argument, NULL, 'S'},
      {L"lldb", no_argument, NULL, 'L'},
      {L"nmake", no_argument, NULL, 'N'},
      {L"help", no_argument, NULL, 'H'},
      {0, 0, 0, 0}
      ///
  };
  while ((ch = getopt_long(Argc, Argv, short_opts, option_long_opt, NULL)) !=
         -1) {
    switch (ch) {
    case 'V':
      vs = optarg;
      break;
    case 'A':
      target = optarg;
      break;
    case 'F':
      flavor = optarg;
      break;
    case 'B':
      channel = kNinjaBootstrap;
      break;
    case 'E':
      channel = kOpenEnvironment;
      break;
    case 'I':
      createInstallPkg = true;
      break;
    case 'C':
      clearEnv = true;
      break;
	case 'R':
      buildReleasedRevision = true;
      break;
    case 'S':
      useStaticCRT = true;
      break;
    case 'L':
      buildLLDB = true;
      break;
    case 'N':
      useNmake = true;
      break;
    case 'H':
      Usage();
      LocalFree(Argv_);
      return 0;
    default:
      break;
    }
  }
  WCHAR szBuffer[UNC_MAX_PATH] = {0};
  StringCbPrintfW(szBuffer, UNC_MAX_PATH, L" -VisualStudio %s -Arch %s", vs,
                  target);
  if (channel!=kOpenEnvironment) {
    StringCbCatW(szBuffer, UNC_MAX_PATH, L" -Flavor ");
    StringCbCatW(szBuffer, UNC_MAX_PATH, flavor);
    if (createInstallPkg) {
      StringCbCatW(szBuffer, UNC_MAX_PATH, L" -Install");
    }
    if (buildReleasedRevision) {
      StringCbCatW(szBuffer, UNC_MAX_PATH, L" -Released");
    }
    if (useStaticCRT) {
      StringCbCatW(szBuffer, UNC_MAX_PATH, L" -Static");
    }
    if (useNmake && channel == kUseMSBuild) {
      StringCbCatW(szBuffer, UNC_MAX_PATH, L" -NMake");
    }
    if (buildLLDB && channel == kUseMSBuild) {
      StringCbCatW(szBuffer, UNC_MAX_PATH, L" -LLDB");
    }
  }
  if (clearEnv) {
    StringCbCatW(szBuffer, UNC_MAX_PATH, L" -Clear");
  }
  auto result = LauncherStartup(szBuffer, channel);
  LocalFree(Argv_);
  return result;
}

int OutErrorMessage(const wchar_t *errorMsg, const wchar_t *errorTitle) {
  int nButton = 0;
  int nRadioButton = 0;
  TASKDIALOGCONFIG tdConfig;
  memset(&tdConfig, 0, sizeof(tdConfig));
  tdConfig.cbSize = sizeof(tdConfig);
  tdConfig.hwndParent = nullptr;
  tdConfig.hInstance = GetModuleHandle(nullptr);
  tdConfig.dwFlags = TDF_ALLOW_DIALOG_CANCELLATION | TDF_EXPAND_FOOTER_AREA |
                     TDF_POSITION_RELATIVE_TO_WINDOW | TDF_SIZE_TO_CONTENT |
                     TDF_ENABLE_HYPERLINKS;
  tdConfig.nDefaultRadioButton = nRadioButton;
  tdConfig.pszWindowTitle = L"Clangbuilder Launcher Error";
  tdConfig.pszMainInstruction = errorTitle;
  tdConfig.hMainIcon = static_cast<HICON>(
      LoadIcon(GetModuleHandle(nullptr), MAKEINTRESOURCE(IDI_ICON_LAUNCHER)));
  tdConfig.dwFlags |= TDF_USE_HICON_MAIN;
  tdConfig.pszContent = errorMsg;
  tdConfig.pszExpandedInformation =
      _T("For more information about this tool, ")
      _T("Visit: <a href=\"https://github.com/fstudio\">Force Charlie</a>");
  tdConfig.pszCollapsedControlText = _T("More information");
  tdConfig.pszExpandedControlText = _T("Less information");
  tdConfig.pfCallback = TaskDialogCallbackProc;
  HRESULT hr = TaskDialogIndirect(&tdConfig, &nButton, &nRadioButton, NULL);
  return hr;
}
