#include "inc/base.hpp"
#include <Windowsx.h>
#include <cassert>
#include <Prsht.h>
#include <CommCtrl.h>
#include <Shlwapi.h>
#include <Shellapi.h>
#include <Shlobj.h>
#include <PathCch.h>
#include <ShellScalingAPI.h>
#include <array>
#include "inc/apphelp.hpp"
#include "inc/apputils.hpp"
#include "appui.hpp"

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

/*
 * Resources Initialize and Release
 */

MainWindow::MainWindow()
    : m_pFactory(nullptr), m_pHwndRenderTarget(nullptr),
      m_pBasicTextBrush(nullptr), m_AreaBorderBrush(nullptr),
      m_pWriteFactory(nullptr), m_pWriteTextFormat(nullptr) {
  tables.Targets =
      std::initializer_list<std::wstring>{L"x86", L"x64", L"ARM", L"ARM64"};
  tables.Configurations = std::initializer_list<std::wstring>{
      L"Release", L"MinSizeRel", L"RelWithDebInfo", L"Debug"};
  tables.AddEngine(L"Ninja - MSVC", L"Ninja");
  tables.AddEngine(L"Ninja - Clang", L"NinjaIterate");
  tables.AddEngine(L"MSBuild - MSVC", L"MSBuild");
  tables.AddEngine(L"Ninja - Bootstrap", L"NinjaBootstrap");
  tables.Branches =
      std::initializer_list<std::wstring>{L"Mainline", L"Stable", L"Release"};
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

LRESULT MainWindow::InitializeWindow() {
  auto hr = CreateDeviceIndependentResources();
  if (hr != S_OK) {
    return hr;
  }
  FLOAT dpiX_, dpiY_;
  m_pFactory->GetDesktopDpi(&dpiX_, &dpiY_);
  //::GetDpiForWindow
  dpiX = static_cast<int>(dpiX_);
  dpiY = static_cast<int>(dpiY_);

  RECT layout = {CW_USEDEFAULT, CW_USEDEFAULT,
                 CW_USEDEFAULT + MulDiv(700, dpiX, 96),
                 CW_USEDEFAULT + MulDiv(540, dpiY, 96)};
  Create(nullptr, layout, L"Clangbuilder Environment Utility",
         WS_NORESIZEWINDOW, WS_EX_APPWINDOW | WS_EX_WINDOWEDGE);
  return S_OK;
}

///
HRESULT MainWindow::CreateDeviceIndependentResources() {
  HRESULT hr = S_OK;
  hr = D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &m_pFactory);
  if (hr != S_OK) {
    return hr;
  }
  hr = DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory),
                           reinterpret_cast<IUnknown **>(&m_pWriteFactory));
  if (hr != S_OK) {
    return hr;
  }
  hr = m_pWriteFactory->CreateTextFormat(
      L"Segoe UI", NULL, DWRITE_FONT_WEIGHT_NORMAL, DWRITE_FONT_STYLE_NORMAL,
      DWRITE_FONT_STRETCH_NORMAL, 12.0f * 96.0f / 72.0f, L"zh-CN",
      &m_pWriteTextFormat);
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
  SafeRelease(&m_pHwndRenderTarget);
  SafeRelease(&m_pBasicTextBrush);
  SafeRelease(&m_AreaBorderBrush);
}
HRESULT MainWindow::OnRender() {
  auto hr = CreateDeviceResources();

  if (hr != S_OK)
    return hr;
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

#define WEXSTYLE                                                               \
  WS_EX_LEFT | WS_EX_LTRREADING | WS_EX_RIGHTSCROLLBAR | WS_EX_NOPARENTNOTIFY
#define CBSTYLE                                                                \
  WS_CHILDWINDOW | WS_CLIPSIBLINGS | WS_VISIBLE | WS_TABSTOP |                 \
      CBS_DROPDOWNLIST | CBS_HASSTRINGS
#define CHECKBOXSTYLE                                                          \
  BS_PUSHBUTTON | BS_TEXT | BS_DEFPUSHBUTTON | BS_CHECKBOX | BS_AUTOCHECKBOX | \
      WS_CHILD | WS_OVERLAPPED | WS_VISIBLE
#define PUSHBUTTONSTYLE                                                        \
  BS_PUSHBUTTON | BS_TEXT | WS_CHILD | WS_OVERLAPPED | WS_VISIBLE

HRESULT MainWindow::InitializeControl() {
  base::error_code ec;
  if (!clangbuilder::LookupClangbuilderTarget(root, targetFile, ec)) {
    MessageBoxW(ec.data(), L"Clangbuilder Error", MB_OK | MB_ICONERROR);
    return S_FALSE;
  }
  settings.Initialize(root);
  if (!search.Execute(root)) {
    return false;
  }

  for (const auto &i : search.Instances()) {
    ::SendMessage(hVisualStudioBox, CB_ADDSTRING, 0,
                  (LPARAM)(i.DisplayName.c_str()));
  }
  auto index = search.Index();
  ::SendMessage(hVisualStudioBox, CB_SETCURSEL, (WPARAM)(index), 0);

  for (const auto &a : tables.Targets) {
    ::SendMessage(hPlatformBox, CB_ADDSTRING, 0, (LPARAM)a.data());
  }
#ifdef _M_X64
  ::SendMessage(hPlatformBox, CB_SETCURSEL, 1, 0);
#else
  if (clangbuilder::IsWow64Process()) {
    ::SendMessage(hPlatformBox, CB_SETCURSEL, 1, 0);
  } else {
    ::SendMessage(hPlatformBox, CB_SETCURSEL, 0, 0);
  }

#endif

  for (const auto &f : tables.Configurations) {
    ::SendMessage(hConfigBox, CB_ADDSTRING, 0, (LPARAM)f.data());
  }

  ::SendMessage(hConfigBox, CB_SETCURSEL, 0, 0);

  for (const auto &e : tables.Engines) {
    ::SendMessage(hBuildBox, CB_ADDSTRING, 0, (LPARAM)e.Desc.data());
  }
  ::SendMessage(hBuildBox, CB_SETCURSEL, 0, 0);

  for (const auto &b : tables.Branches) {
    ::SendMessage(hBranchBox, CB_ADDSTRING, 0, (LPARAM)b.data());
  }
  ::SendMessage(hBranchBox, CB_SETCURSEL, 0, 0);

  // Button_SetCheck(hCheckLink_, 1);
  return S_OK;
}

/////
struct ACCENTPOLICY {
  int nAccentState;
  int nFlags;
  int nColor;
  int nAnimationId;
};
struct WINCOMPATTRDATA {
  int nAttribute;
  PVOID pData;
  ULONG ulDataSize;
};

enum AccentTypes {
  ACCENT_DISABLED = 0,        // Black and solid background
  ACCENT_ENABLE_GRADIENT = 1, // Custom-colored solid background
  ACCENT_ENABLE_TRANSPARENTGRADIENT =
      2, // Custom-colored transparent background
  ACCENT_ENABLE_BLURBEHIND =
      3,                    // Custom-colored and blurred transparent background
  ACCENT_ENABLE_FLUENT = 4, // Custom-colored Fluent effect
  ACCENT_INVALID_STATE = 5  // Completely transparent background
};

bool SetWindowCompositionAttributeImpl(HWND hWnd) {
  typedef BOOL(WINAPI * pSetWindowCompositionAttribute)(HWND,
                                                        WINCOMPATTRDATA *);
  bool result = false;
  const HINSTANCE hModule = LoadLibrary(TEXT("user32.dll"));
  const pSetWindowCompositionAttribute SetWindowCompositionAttribute =
      (pSetWindowCompositionAttribute)GetProcAddress(
          hModule, "SetWindowCompositionAttribute");

  // Only works on Win10
  if (SetWindowCompositionAttribute) {
    ACCENTPOLICY policy = {ACCENT_ENABLE_FLUENT, 0, 0, 0};
    WINCOMPATTRDATA data = {19, &policy, sizeof(ACCENTPOLICY)};
    result = SetWindowCompositionAttribute(hWnd, &data);
  }
  FreeLibrary(hModule);
  return result;
}

/*
 *  Message Action Function
 */
LRESULT MainWindow::OnCreate(UINT nMsg, WPARAM wParam, LPARAM lParam,
                             BOOL &bHandle) {
  HICON hIcon = LoadIconW(GetModuleHandleW(nullptr),
                          MAKEINTRESOURCEW(IDI_CLANGBUILDERUI));
  if (settings.SetWindowCompositionAttributeEnabled()) {
    SetWindowCompositionAttributeImpl(m_hWnd);
  }

  SetIcon(hIcon, TRUE);
  hFont = (HFONT)GetStockObject(DEFAULT_GUI_FONT);
  LOGFONTW logFont = {0};
  GetObjectW(hFont, sizeof(logFont), &logFont);
  DeleteObject(hFont);
  hFont = nullptr;
  logFont.lfHeight = -MulDiv(14, dpiY, 96);
  logFont.lfWeight = FW_NORMAL;
  wcscpy_s(logFont.lfFaceName, L"Segoe UI");
  hFont = CreateFontIndirectW(&logFont);
  auto MakeWindow = [&](LPCWSTR lpClassName, LPCWSTR lpWindowName,
                        DWORD dwStyle, int X, int Y, int nWidth, int nHeight,
                        HMENU hMenu) -> HWND {
    auto hw = CreateWindowExW(
        WEXSTYLE, lpClassName, lpWindowName, dwStyle, MulDiv(X, dpiX, 96),
        MulDiv(Y, dpiY, 96), MulDiv(nWidth, dpiX, 96),
        MulDiv(nHeight, dpiY, 96), m_hWnd, hMenu, HINST_THISCOMPONENT, nullptr);
    if (hw) {
      ::SendMessageW(hw, WM_SETFONT, (WPARAM)hFont, lParam);
    }
    return hw;
  };
  hVisualStudioBox =
      MakeWindow(WC_COMBOBOXW, L"", CBSTYLE, 200, 20, 400, 30, nullptr);
  hPlatformBox =
      MakeWindow(WC_COMBOBOXW, L"", CBSTYLE, 200, 60, 400, 30, nullptr);
  hConfigBox =
      MakeWindow(WC_COMBOBOXW, L"", CBSTYLE, 200, 100, 400, 30, nullptr);
  hBranchBox =
      MakeWindow(WC_COMBOBOXW, L"", CHECKBOXSTYLE, 200, 140, 400, 30, nullptr);
  hBuildBox = MakeWindow(WC_COMBOBOXW, L"", CHECKBOXSTYLE, 200, 180, 400, 30,
                         (HMENU)IDM_ENGINE_COMBOX);

  hLibcxx_ = MakeWindow(WC_BUTTONW, L"Build Libcxx on Windows", CHECKBOXSTYLE,
                        200, 230, 360, 27, nullptr);
  ::EnableWindow(hLibcxx_, FALSE);
  hCheckLTO_ = MakeWindow(WC_BUTTONW, L"Clang/LLVM bootstrap with ThinLTO",
                          CHECKBOXSTYLE, 200, 260, 360, 27, nullptr);

  hCheckSdklow_ =
      MakeWindow(WC_BUTTONW, L"SDK Compatibility (Windows 8.1 SDK) (Env)",
                 CHECKBOXSTYLE, 200, 290, 360, 27, nullptr);

  hCheckPackaged_ = MakeWindow(WC_BUTTONW, L"Create Installation Package",
                               CHECKBOXSTYLE, 200, 320, 360, 27, nullptr);
  hCheckCleanEnv_ = MakeWindow(WC_BUTTONW, L"Use Clean Environment (Env)",
                               CHECKBOXSTYLE, 200, 350, 360, 27, nullptr);
  hCheckLLDB_ =
      MakeWindow(WC_BUTTONW, L"Build LLDB (Visual Studio 2015 or Later)",
                 CHECKBOXSTYLE, 200, 380, 360, 27, nullptr);
  // Button_SetElevationRequiredState
  hButtonTask_ = MakeWindow(WC_BUTTONW, L"Building", PUSHBUTTONSTYLE, 200, 430,
                            195, 30, (HMENU)IDC_BUTTON_STARTTASK);
  hButtonEnv_ =
      MakeWindow(WC_BUTTONW, L"Environment Console", PUSHBUTTONSTYLE | BS_ICON,
                 405, 430, 195, 30, (HMENU)IDC_BUTTON_STARTENV);

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
  // SEE:
  // https://msdn.microsoft.com/en-us/library/windows/desktop/dd371319(v=vs.85).aspx
  m_pFactory->ReloadSystemMetrics();
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
  UpdateWindowPos(hCheckLTO_);
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
  utils::PrivMessageBox(m_hWnd, L"About Clangbuilder", CLANGBUILDER_APPVERSION,
                        CLANGBUILDER_APPLINK, utils::kAboutWindow);
  return S_OK;
}

/*
 * ClangbuilderTarget.ps1
 */

LRESULT MainWindow::OnChangeEngine(WORD wNotifyCode, WORD wID, HWND hWndCtl,
                                   BOOL &bHandled) {
  if (wNotifyCode == CBN_SELCHANGE) {
    auto N = ComboBox_GetCurSel(hBuildBox);
    if (N == 1 || N == 3) {
      ::EnableWindow(hLibcxx_, TRUE);
    } else {
      ::EnableWindow(hLibcxx_, FALSE);
    }
  }
  return S_OK;
}