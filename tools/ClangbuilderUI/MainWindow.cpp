#include "stdafx.h"
#include <cassert>
#include <Prsht.h>
#include <CommCtrl.h>
#include <Shlwapi.h>
#include <Shellapi.h>
#include <Shlobj.h>
#include <PathCch.h>
#include <ShellScalingAPI.h>
#include <array>
#include "MainWindow.h"
#include "MessageWindow.h"

#ifndef HINST_THISCOMPONENT
EXTERN_C IMAGE_DOS_HEADER __ImageBase;
#define HINST_THISCOMPONENT ((HINSTANCE)&__ImageBase)
#endif

#define WS_NORESIZEWINDOW                                                      \
  (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_CLIPCHILDREN | WS_MINIMIZEBOX)

template <class Interface>
inline void SafeRelease(Interface **ppInterfaceToRelease) {
  if (*ppInterfaceToRelease != NULL) {
    (*ppInterfaceToRelease)->Release();

    (*ppInterfaceToRelease) = NULL;
  }
}

int RectHeight(RECT Rect) { return Rect.bottom - Rect.top; }

int RectWidth(RECT Rect) { return Rect.right - Rect.left; }

const wchar_t *Platforms[] = {L"x86", L"x64", L"ARM", L"ARM64"};
const wchar_t *Configurations[] = {L"Release", L"MinSizeRel", L"RelWithDebInfo",
                                   L"Debug"};
const wchar_t *Rules[] = {L"MSBuild", L"Ninja", L"NinjaBootstrap",
                          L"NinjaIterate"};
const wchar_t *BranchTable[] = {L"Mainline", L"Stable", L"Release"};

/*
 * Resources Initialize and Release
 */

MainWindow::MainWindow()
    : m_pFactory(nullptr), m_pHwndRenderTarget(nullptr),
      m_pBasicTextBrush(nullptr), m_AreaBorderBrush(nullptr),
      m_pWriteFactory(nullptr), m_pWriteTextFormat(nullptr) {
  ///
}
MainWindow::~MainWindow() {
  SafeRelease(&m_pWriteTextFormat);
  SafeRelease(&m_pWriteFactory);
  SafeRelease(&m_pBasicTextBrush);
  SafeRelease(&m_AreaBorderBrush);
  SafeRelease(&m_pHwndRenderTarget);
  SafeRelease(&m_pFactory);
  if (hFont != nullptr) {
    DeleteFont(hFont);
  }
}

HRESULT MainWindow::Initialize() {
  auto hr = CreateDeviceIndependentResources();
  FLOAT dpiX_, dpiY_;
  m_pFactory->GetDesktopDpi(&dpiX_, &dpiY_);
  dpiX = static_cast<int>(dpiX_);
  dpiY = static_cast<int>(dpiY_);
  return hr;
}

LRESULT MainWindow::InitializeWindow() {
  HRESULT hr = E_FAIL;

  RECT layout = {100, 100, 800, 640};
  Create(nullptr, layout, L"Clangbuilder Environment Utility",
         WS_NORESIZEWINDOW, WS_EX_APPWINDOW | WS_EX_WINDOWEDGE);
  return S_OK;
}

///
HRESULT MainWindow::CreateDeviceIndependentResources() {
  HRESULT hr = S_OK;
  hr = D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &m_pFactory);
  return hr;
}

HRESULT MainWindow::CreateDeviceResources() {
  HRESULT hr = S_OK;

  if (!m_pHwndRenderTarget) {
    RECT rc;
    ::GetClientRect(m_hWnd, &rc);
    D2D1_SIZE_U size = D2D1::SizeU(rc.right - rc.left, rc.bottom - rc.top);
    hr = m_pFactory->CreateHwndRenderTarget(
        D2D1::RenderTargetProperties(),
        D2D1::HwndRenderTargetProperties(m_hWnd, size), &m_pHwndRenderTarget);
    if (SUCCEEDED(hr)) {
      hr = m_pHwndRenderTarget->CreateSolidColorBrush(
          D2D1::ColorF(D2D1::ColorF::Black), &m_pBasicTextBrush);
    }
    if (SUCCEEDED(hr)) {
      hr = m_pHwndRenderTarget->CreateSolidColorBrush(D2D1::ColorF(0xFFC300),
                                                      &m_AreaBorderBrush);
    }
  }
  return hr;
}
void MainWindow::DiscardDeviceResources() {
  ///
  SafeRelease(&m_pBasicTextBrush);
}
HRESULT MainWindow::OnRender() {
  auto hr = CreateDeviceResources();
  hr = DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory),
                           reinterpret_cast<IUnknown **>(&m_pWriteFactory));
  if (hr != S_OK)
    return hr;
  hr = m_pWriteFactory->CreateTextFormat(
      L"Segoe UI", NULL, DWRITE_FONT_WEIGHT_NORMAL, DWRITE_FONT_STYLE_NORMAL,
      DWRITE_FONT_STRETCH_NORMAL, 12.0f * 96.0f / 72.0f, L"zh-CN",
      &m_pWriteTextFormat);
#pragma warning(disable : 4244)
#pragma warning(disable : 4267)
  if (SUCCEEDED(hr)) {

    auto dsz = m_pHwndRenderTarget->GetSize();
    m_pHwndRenderTarget->BeginDraw();
    m_pHwndRenderTarget->SetTransform(D2D1::Matrix3x2F::Identity());
    m_pHwndRenderTarget->Clear(D2D1::ColorF(D2D1::ColorF::White, 1.0f));

    m_pHwndRenderTarget->DrawRectangle(
        D2D1::RectF(20, 10, dsz.width - 20, dsz.height - 20), m_AreaBorderBrush,
        1.0);
    m_pHwndRenderTarget->DrawLine(D2D1::Point2F(20, 220),
                                  D2D1::Point2F(dsz.width - 20, 220),
                                  m_AreaBorderBrush, 1.0);

    for (auto &label : label_) {
      if (label.text.empty())
        continue;
      m_pHwndRenderTarget->DrawTextW(
          label.text.c_str(), label.text.size(), m_pWriteTextFormat,
          D2D1::RectF(label.layout.left, label.layout.top, label.layout.right,
                      label.layout.bottom),
          m_pBasicTextBrush, D2D1_DRAW_TEXT_OPTIONS_ENABLE_COLOR_FONT,
          DWRITE_MEASURING_MODE_NATURAL);
    }
    m_pWriteTextFormat->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
    hr = m_pHwndRenderTarget->EndDraw();
  }
#pragma warning(default : 4244)
#pragma warning(default : 4267)
  if (hr == D2DERR_RECREATE_TARGET) {
    hr = S_OK;
    DiscardDeviceResources();
    ::InvalidateRect(m_hWnd, nullptr, FALSE);
  }
  return hr;
}
D2D1_SIZE_U MainWindow::CalculateD2DWindowSize() {
  RECT rc;
  ::GetClientRect(m_hWnd, &rc);

  D2D1_SIZE_U d2dWindowSize = {0};
  d2dWindowSize.width = rc.right;
  d2dWindowSize.height = rc.bottom;

  return d2dWindowSize;
}

void MainWindow::OnResize(UINT width, UINT height) {
  if (m_pHwndRenderTarget) {
    m_pHwndRenderTarget->Resize(D2D1::SizeU(width, height));
  }
}

#define WINDOWEXSTYLE                                                          \
  WS_EX_LEFT | WS_EX_LTRREADING | WS_EX_RIGHTSCROLLBAR | WS_EX_NOPARENTNOTIFY
#define COMBOBOXSTYLE                                                          \
  WS_CHILDWINDOW | WS_CLIPSIBLINGS | WS_VISIBLE | WS_TABSTOP |                 \
      CBS_DROPDOWNLIST | CBS_HASSTRINGS
#define CHECKBOXSTYLE                                                          \
  BS_PUSHBUTTON | BS_TEXT | BS_DEFPUSHBUTTON | BS_CHECKBOX | BS_AUTOCHECKBOX | \
      WS_CHILD | WS_OVERLAPPED | WS_VISIBLE
#define PUSHBUTTONSTYLE                                                        \
  BS_PUSHBUTTON | BS_TEXT | WS_CHILD | WS_OVERLAPPED | WS_VISIBLE

HRESULT MainWindow::InitializeControl() {
  if (!InitializeClangbuilderTarget()) {
    MessageBoxW(L"Initialize Clangbuilder Environemnt Error",
                L"Clangbuilder Error", MB_OK | MB_ICONERROR);
    return S_FALSE;
  }

  if (!VisualStudioSearch(root, instances_)) {
    return S_FALSE;
  }
  assert(hVisualStudioBox);
  assert(hPlatformBox);
  assert(hConfigBox);
  assert(hBuildBox);
  assert(hBranchBox);
  assert(hCheckPackaged_);
  assert(hCheckCleanEnv_);
  assert(hCheckLLDB_);
  assert(hButtonTask_);
  assert(hButtonEnv_);

  for (auto &i : instances_) {
    ::SendMessage(hVisualStudioBox, CB_ADDSTRING, 0,
                  (LPARAM)(i.description.c_str()));
  }
  int index = instances_.empty() ? 0 : (instances_.size() - 1);
  ::SendMessage(hVisualStudioBox, CB_SETCURSEL, (WPARAM)(index), 0);

  for (auto &a : Platforms) {
    ::SendMessage(hPlatformBox, CB_ADDSTRING, 0, (LPARAM)a);
  }
#ifdef _M_X64
  ::SendMessage(hPlatformBox, CB_SETCURSEL, 1, 0);
#else
  if (KrIsWow64Process()) {
    ::SendMessage(hPlatformBox, CB_SETCURSEL, 1, 0);
  } else {
    ::SendMessage(hPlatformBox, CB_SETCURSEL, 0, 0);
  }

#endif

  for (auto &f : Configurations) {
    ::SendMessage(hConfigBox, CB_ADDSTRING, 0, (LPARAM)f);
  }

  ::SendMessage(hConfigBox, CB_SETCURSEL, 0, 0);

  for (auto e : Rules) {
    ::SendMessage(hBuildBox, CB_ADDSTRING, 0, (LPARAM)e);
  }
  ::SendMessage(hBuildBox, CB_SETCURSEL, 0, 0);

  for (auto b : BranchTable) {
    ::SendMessage(hBranchBox, CB_ADDSTRING, 0, (LPARAM)b);
  }
  ::SendMessage(hBranchBox, CB_SETCURSEL, 0, 0);

  // Button_SetCheck(hCheckLink_, 1);
  return S_OK;
}

/*
 *  Message Action Function
 */
LRESULT MainWindow::OnCreate(UINT nMsg, WPARAM wParam, LPARAM lParam,
                             BOOL &bHandle) {
  auto hr = Initialize();
  if (hr != S_OK) {
    ::MessageBoxW(nullptr, L"Initialize() failed", L"Fatal error",
                  MB_OK | MB_ICONSTOP);
    std::terminate();
    return S_FALSE;
  }
  HICON hIcon = LoadIconW(GetModuleHandleW(nullptr),
                          MAKEINTRESOURCEW(IDI_CLANGBUILDERUI));
  SetIcon(hIcon, TRUE);
  this->MoveWindow(MulDiv(100, dpiX, 96), MulDiv(100, dpiY, 96),
                   MulDiv(700, dpiX, 96), MulDiv(500, dpiY, 96));
  hFont = (HFONT)GetStockObject(DEFAULT_GUI_FONT);
  LOGFONTW logFont = {0};
  GetObjectW(hFont, sizeof(logFont), &logFont);
  DeleteObject(hFont);
  hFont = nullptr;
  logFont.lfHeight = -MulDiv(14, dpiY, 96);
  logFont.lfWeight = FW_NORMAL;
  wcscpy_s(logFont.lfFaceName, L"Segoe UI");
  hFont = CreateFontIndirectW(&logFont);
  auto LambdaCreateWindow = [&](LPCWSTR lpClassName, LPCWSTR lpWindowName,
                                DWORD dwStyle, int X, int Y, int nWidth,
                                int nHeight, HMENU hMenu) -> HWND {
    auto hw = CreateWindowExW(
        WINDOWEXSTYLE, lpClassName, lpWindowName, dwStyle, MulDiv(X, dpiX, 96),
        MulDiv(Y, dpiY, 96), MulDiv(nWidth, dpiX, 96),
        MulDiv(nHeight, dpiY, 96), m_hWnd, hMenu, HINST_THISCOMPONENT, nullptr);
    if (hw) {
      ::SendMessageW(hw, WM_SETFONT, (WPARAM)hFont, lParam);
    }
    return hw;
  };
  hVisualStudioBox = LambdaCreateWindow(WC_COMBOBOXW, L"", COMBOBOXSTYLE, 200,
                                        20, 400, 30, nullptr);
  hPlatformBox = LambdaCreateWindow(WC_COMBOBOXW, L"", COMBOBOXSTYLE, 200, 60,
                                    400, 30, nullptr);
  hConfigBox = LambdaCreateWindow(WC_COMBOBOXW, L"", COMBOBOXSTYLE, 200, 100,
                                  400, 30, nullptr);
  hBranchBox = LambdaCreateWindow(WC_COMBOBOXW, L"", CHECKBOXSTYLE, 200, 140,
                                  400, 30, nullptr);
  hBuildBox = LambdaCreateWindow(WC_COMBOBOXW, L"", CHECKBOXSTYLE, 200, 180,
                                 400, 30, nullptr);

  /* hBranchBox = LambdaCreateWindow(WC_BUTTONW, L"Build the latest release",
  CHECKBOXSTYLE, 200, 220, 360, 27, nullptr);*/

  hCheckSdklow_ = LambdaCreateWindow(
      WC_BUTTONW, L"SDK Compatibility (Windows 8.1 SDK) (Env)", CHECKBOXSTYLE,
      200, 230, 360, 27, nullptr);

  hCheckPackaged_ =
      LambdaCreateWindow(WC_BUTTONW, L"Create Installation Package",
                         CHECKBOXSTYLE, 200, 260, 360, 27, nullptr);
  hCheckCleanEnv_ =
      LambdaCreateWindow(WC_BUTTONW, L"Use Clean Environment (Env)",
                         CHECKBOXSTYLE, 200, 290, 360, 27, nullptr);
  hCheckLLDB_ = LambdaCreateWindow(WC_BUTTONW,
                                   L"Build LLDB (Visual Studio 2015 or Later)",
                                   CHECKBOXSTYLE, 200, 320, 360, 27, nullptr);
  // Button_SetElevationRequiredState
  hButtonTask_ =
      LambdaCreateWindow(WC_BUTTONW, L"Building", PUSHBUTTONSTYLE, 200, 380,
                         195, 30, (HMENU)IDC_BUTTON_STARTTASK);
  hButtonEnv_ = LambdaCreateWindow(WC_BUTTONW, L"Environment Console",
                                   PUSHBUTTONSTYLE | BS_ICON, 405, 380, 195, 30,
                                   (HMENU)IDC_BUTTON_STARTENV);

  HMENU hSystemMenu = ::GetSystemMenu(m_hWnd, FALSE);
  InsertMenuW(hSystemMenu, SC_CLOSE, MF_ENABLED, IDM_CLANGBUILDER_ABOUT,
              L"About ClangbuilderUI\tAlt+F1");

  label_.push_back(KryceLabel(30, 20, 190, 50, L"Distribution\t\xD83C\xDD9A:"));
  label_.push_back(KryceLabel(30, 60, 190, 90, L"Architecture\t\xD83D\xDCBB:"));
  label_.push_back(KryceLabel(30, 100, 190, 130, L"Configuration\t\x2699:"));
  label_.push_back(KryceLabel(30, 140, 190, 170, L"Branches\t\t\x26A1:"));
  label_.push_back(KryceLabel(30, 180, 190, 210, L"Engine\t\t\xD83D\xDEE0:"));
  label_.push_back(KryceLabel(30, 230, 190, 270, L"Build Options\t\x2611:"));
  ///
  if (FAILED(InitializeControl())) {
  }
  return S_OK;
}
LRESULT MainWindow::OnDestroy(UINT nMsg, WPARAM wParam, LPARAM lParam,
                              BOOL &bHandle) {
  PostQuitMessage(0);
  return S_OK;
}
LRESULT MainWindow::OnClose(UINT nMsg, WPARAM wParam, LPARAM lParam,
                            BOOL &bHandle) {
  ::DestroyWindow(m_hWnd);
  return S_OK;
}
LRESULT MainWindow::OnSize(UINT nMsg, WPARAM wParam, LPARAM lParam,
                           BOOL &bHandle) {
  UINT width = LOWORD(lParam);
  UINT height = HIWORD(lParam);
  OnResize(width, height);
  return S_OK;
}
LRESULT MainWindow::OnDpiChanged(UINT nMsg, WPARAM wParam, LPARAM lParam,
                                 BOOL &bHandle) {
  /// GET new dpi
  FLOAT dpiX_, dpiY_;
  m_pFactory->GetDesktopDpi(&dpiX_, &dpiY_);
  dpiX = static_cast<int>(dpiX_);
  dpiY = static_cast<int>(dpiY_);
  RECT *const prcNewWindow = (RECT *)lParam;
  ::SetWindowPos(m_hWnd, NULL, prcNewWindow->left, prcNewWindow->top,
                 MulDiv(prcNewWindow->right - prcNewWindow->left, dpiX, 96),
                 MulDiv(prcNewWindow->bottom - prcNewWindow->top, dpiY, 96),
                 SWP_NOZORDER | SWP_NOACTIVATE);
  LOGFONTW logFont = {0};
  GetObjectW(hFont, sizeof(logFont), &logFont);
  DeleteObject(hFont);
  hFont = nullptr;
  logFont.lfHeight = -MulDiv(14, dpiY, 96);
  logFont.lfWeight = FW_NORMAL;
  wcscpy_s(logFont.lfFaceName, L"Segoe UI");
  hFont = CreateFontIndirectW(&logFont);
  auto UpdateWindowPos = [&](HWND hWnd) {
    RECT rect;
    ::GetClientRect(hWnd, &rect);
    ::SetWindowPos(hWnd, NULL, MulDiv(rect.left, dpiX, 96),
                   MulDiv(rect.top, dpiY, 96),
                   MulDiv(rect.right - rect.left, dpiX, 96),
                   MulDiv(rect.bottom - rect.top, dpiY, 96),
                   SWP_NOZORDER | SWP_NOACTIVATE);
    ::SendMessageW(hWnd, WM_SETFONT, (WPARAM)hFont, lParam);
  };
  UpdateWindowPos(hVisualStudioBox);
  UpdateWindowPos(hPlatformBox);
  UpdateWindowPos(hConfigBox);
  UpdateWindowPos(hBranchBox);
  UpdateWindowPos(hBuildBox);
  UpdateWindowPos(hCheckSdklow_);
  UpdateWindowPos(hCheckPackaged_);
  UpdateWindowPos(hCheckCleanEnv_);
  UpdateWindowPos(hCheckLLDB_);
  UpdateWindowPos(hButtonTask_);
  UpdateWindowPos(hButtonEnv_);
  return S_OK;
}
LRESULT MainWindow::OnPaint(UINT nMsg, WPARAM wParam, LPARAM lParam,
                            BOOL &bHandle) {
  LRESULT hr = S_OK;
  PAINTSTRUCT ps;
  BeginPaint(&ps);
  /// if auto return OnRender(),CPU usage is too high
  hr = OnRender();
  EndPaint(&ps);
  return hr;
}

LRESULT MainWindow::OnCtlColorStatic(UINT nMsg, WPARAM wParam, LPARAM lParam,
                                     BOOL &bHandle) {
  return S_OK;
}

LRESULT MainWindow::OnSysMemuAbout(WORD wNotifyCode, WORD wID, HWND hWndCtl,
                                   BOOL &bHandled) {
  MessageWindowEx(m_hWnd, L"About Clangbuilder",
                  L"Prerelease: 3.1\nCopyright \xA9 2018, Force Charlie. "
                  L"All Rights Reserved.",
                  L"For more information about this tool.\nVisit: <a "
                  L"href=\"http://forcemz.net/\">forcemz.net</a>",
                  kAboutWindow);
  return S_OK;
}

/*
 * ClangbuilderTarget.ps1
 */

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

bool InitializeSearchPowershell(std::wstring &ps) {
  WCHAR pszPath[MAX_PATH]; /// by default , System Dir Length <260
  if (SHGetFolderPathW(nullptr, CSIDL_SYSTEM, nullptr, 0, pszPath) != S_OK) {
    return false;
  }
  ps.assign(pszPath);
  ps.append(L"\\WindowsPowerShell\\v1.0\\powershell.exe");
  return true;
}

#ifndef _M_X64
class FsRedirection {
public:
  typedef BOOL WINAPI fntype_Wow64DisableWow64FsRedirection(PVOID *OldValue);
  typedef BOOL WINAPI fntype_Wow64RevertWow64FsRedirection(PVOID *OldValue);
  FsRedirection() {
    auto hModule = KrModule();
    auto pfnWow64DisableWow64FsRedirection =
        (fntype_Wow64DisableWow64FsRedirection *)GetProcAddress(
            hModule, "Wow64DisableWow64FsRedirection");
    if (pfnWow64DisableWow64FsRedirection) {
      pfnWow64DisableWow64FsRedirection(&OldValue);
    }
  }
  ~FsRedirection() {
    auto hModule = KrModule();
    auto pfnWow64RevertWow64FsRedirection =
        (fntype_Wow64RevertWow64FsRedirection *)GetProcAddress(
            hModule, "Wow64RevertWow64FsRedirection");
    if (pfnWow64RevertWow64FsRedirection) {
      pfnWow64RevertWow64FsRedirection(&OldValue);
    }
  }

private:
  PVOID OldValue = NULL;
};
#endif

bool PsCreateProcess(LPWSTR pszCommand) {
  PROCESS_INFORMATION pi;
  STARTUPINFO si;
  ZeroMemory(&si, sizeof(si));
  ZeroMemory(&pi, sizeof(pi));
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESHOWWINDOW;
  si.wShowWindow = SW_SHOW;
#ifdef _M_IX86 //// Only x86 on Windows 64
  FsRedirection fsRedirection;
#endif
  if (CreateProcessW(nullptr, pszCommand, NULL, NULL, FALSE,
                     CREATE_NEW_CONSOLE | NORMAL_PRIORITY_CLASS, NULL, NULL,
                     &si, &pi)) {
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return true;
  }
  return false;
}

LPWSTR FormatMessageInternal() {
  LPWSTR hlocal;
  if (FormatMessageW(
          FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS |
              FORMAT_MESSAGE_ALLOCATE_BUFFER,
          NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL),
          (LPWSTR)&hlocal, 0, NULL)) {
    return hlocal;
  }
  return nullptr;
}

LRESULT MainWindow::OnBuildNow(WORD wNotifyCode, WORD wID, HWND hWndCtl,
                               BOOL &bHandled) {
  std::wstring Command;
  if (!InitializeSearchPowershell(Command)) {
    MessageWindowEx(m_hWnd, L"Search PowerShell Error",
                    L"Please check PowerShell", nullptr, kFatalWindow);
    return S_FALSE;
  }

  Command.append(L" -NoLogo -NoExit   -File \"")
      .append(targetFile)
      .push_back('"');
  auto vsindex_ = ComboBox_GetCurSel(hVisualStudioBox);
  if (vsindex_ < 0 || instances_.size() <= (size_t)vsindex_) {
    return S_FALSE;
  }
  auto archindex_ = ComboBox_GetCurSel(hPlatformBox);
  if (archindex_ < 0 || ARRAYSIZE(Platforms) <= archindex_) {
    return S_FALSE;
  }
  int xver = 0;
  wchar_t *mm = nullptr;
  xver = wcstoul(instances_[vsindex_].installversion.c_str(), &mm, 10);
  if (xver < 15 && archindex_ >= 3) {
    MessageWindowEx(m_hWnd, L"This toolchain does not support ARM64",
                    L"Please use Visual Studio 15.4 or Later (CppDailyTools "
                    L"14.13.26310 or Later)",
                    nullptr, kFatalWindow);
    return S_FALSE;
  }
  auto flavor_ = ComboBox_GetCurSel(hConfigBox);
  if (flavor_ < 0 || ARRAYSIZE(Configurations) <= flavor_) {
    return S_FALSE;
  }

  auto be = ComboBox_GetCurSel(hBuildBox);
  if (be < 0 || ARRAYSIZE(Rules) <= be) {
    return S_FALSE;
  }

  auto bs = ComboBox_GetCurSel(hBranchBox);
  if (bs < 0 || ARRAYSIZE(BranchTable) <= bs) {
    return S_FALSE;
  }

  Command.append(L" -InstanceId ").append(instances_[vsindex_].instanceId);
  Command.append(L" -InstallationVersion ")
      .append(instances_[vsindex_].installversion);
  Command.append(L" -Arch ").append(Platforms[archindex_]);
  Command.append(L" -Flavor ").append(Configurations[flavor_]);
  Command.append(L" -Engine ").append(Rules[be]);
  Command.append(L" -Branch ").append(BranchTable[bs]);

  if (Button_GetCheck(hCheckSdklow_) == BST_CHECKED) {
    Command.append(L" -Sdklow");
  }

  if (Button_GetCheck(hCheckPackaged_) == BST_CHECKED) {
    Command.append(L" -Package");
  }

  if (Button_GetCheck(hCheckLLDB_) == BST_CHECKED) {
    Command.append(L" -LLDB");
  }

  if (Button_GetCheck(hCheckCleanEnv_) == BST_CHECKED) {
    Command.append(L" -ClearEnv");
  }
  if (!PsCreateProcess(&Command[0])) {
    ////
    auto errmsg = FormatMessageInternal();
    if (errmsg) {
      MessageWindowEx(m_hWnd, L"CreateProcess failed", errmsg, nullptr,
                      kFatalWindow);
      LocalFree(errmsg);
    }
  }
  return S_OK;
}
LRESULT MainWindow::OnStartupEnv(WORD wNotifyCode, WORD wID, HWND hWndCtl,
                                 BOOL &bHandled) {
  std::wstring Command;
  if (!InitializeSearchPowershell(Command)) {
    MessageWindowEx(m_hWnd, L"Search PowerShell Error",
                    L"Please check PowerShell", nullptr, kFatalWindow);
    return S_FALSE;
  }

  Command.append(L" -NoLogo -NoExit   -File \"")
      .append(targetFile)
      .push_back('"');
  auto vsindex_ = ComboBox_GetCurSel(hVisualStudioBox);
  if (vsindex_ < 0 || instances_.size() <= (size_t)vsindex_) {
    return S_FALSE;
  }
  auto archindex_ = ComboBox_GetCurSel(hPlatformBox);
  if (archindex_ < 0 || sizeof(Platforms) <= archindex_) {
    return S_FALSE;
  }
  int xver = 0;
  wchar_t *mm = nullptr;
  xver = wcstoul(instances_[vsindex_].installversion.c_str(), &mm, 10);
  if (xver < 15 && archindex_ >= 3) {
    MessageWindowEx(m_hWnd, L"This toolchain does not support ARM64",
                    L"Please use Visual Studio 15.4 or Later (CppDailyTools "
                    L"14.13.26310 or Later)",
                    nullptr, kFatalWindow);
    return S_FALSE;
  }
  Command.append(L" -Environment -InstanceId ")
      .append(instances_[vsindex_].instanceId);
  Command.append(L" -InstallationVersion ")
      .append(instances_[vsindex_].installversion);
  Command.append(L" -Arch ").append(Platforms[archindex_]);
  if (Button_GetCheck(hCheckSdklow_) == BST_CHECKED) {
    Command.append(L" -Sdklow");
  }
  if (Button_GetCheck(hCheckCleanEnv_) == BST_CHECKED) {
    Command.append(L" -ClearEnv");
  }

  if (!PsCreateProcess(&Command[0])) {
    auto errmsg = FormatMessageInternal();
    if (errmsg) {
      MessageWindowEx(m_hWnd, L"CreateProcess failed", errmsg, nullptr,
                      kFatalWindow);
      LocalFree(errmsg);
    }
  }
  return S_OK;
}