///
#include <bela/base.hpp>
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
#include <appfs.hpp>
#include <bela/picker.hpp>
#include "appui.hpp"

#ifndef HINST_THISCOMPONENT
EXTERN_C IMAGE_DOS_HEADER __ImageBase;
#define HINST_THISCOMPONENT ((HINSTANCE)&__ImageBase)
#endif

constexpr const auto noresizewnd = (WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU |
                                    WS_CLIPCHILDREN | WS_MINIMIZEBOX);
constexpr const auto wexstyle =
    WS_EX_LEFT | WS_EX_LTRREADING | WS_EX_RIGHTSCROLLBAR | WS_EX_NOPARENTNOTIFY;

constexpr const auto cbstyle = WS_CHILDWINDOW | WS_CLIPSIBLINGS | WS_VISIBLE |
                               WS_TABSTOP | CBS_DROPDOWNLIST | CBS_HASSTRINGS;
constexpr const auto chboxstyle = BS_PUSHBUTTON | BS_TEXT | BS_DEFPUSHBUTTON |
                                  BS_CHECKBOX | BS_AUTOCHECKBOX | WS_CHILD |
                                  WS_OVERLAPPED | WS_VISIBLE;
constexpr const auto pbstyle =
    BS_PUSHBUTTON | BS_TEXT | WS_CHILD | WS_OVERLAPPED | WS_VISIBLE;

// Resources Safe Release
template <typename I> inline void Free(I **i) {
  if (*i != nullptr) {
    (*i)->Release();
  }
  *i = nullptr;
}

MainWindow::MainWindow() {
  hInst = ((HINSTANCE)&__ImageBase);
  //
}

MainWindow::~MainWindow() {
  Free(&writeTextFormat);
  Free(&writeFactory);
  Free(&textBrush);
  Free(&borderBrush);
  Free(&renderTarget);
  Free(&m_pFactory);
  if (hFont != nullptr) {
    DeleteFont(hFont);
  }
}

LRESULT MainWindow::InitializeWindow() {
  if (CreateDeviceIndependentResources() != S_OK) {
    return S_FALSE;
  }

  RECT layout = {100, 100, 800, 640};
  Create(nullptr, layout, L"Clangbuilder Environment Utility", noresizewnd,
         WS_EX_APPWINDOW | WS_EX_WINDOWEDGE);
  return S_OK;
}

///
HRESULT MainWindow::CreateDeviceIndependentResources() {
  HRESULT hr = S_OK;
  hr = D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &m_pFactory);
  if (FAILED(hr)) {
    return hr;
  }
  hr = DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory),
                           reinterpret_cast<IUnknown **>(&writeFactory));
  if (FAILED(hr)) {
    return hr;
  }
  hr = writeFactory->CreateTextFormat(
      L"Segoe UI", NULL, DWRITE_FONT_WEIGHT_NORMAL, DWRITE_FONT_STYLE_NORMAL,
      DWRITE_FONT_STRETCH_NORMAL, 12.0f * 96.0f / 72.0f, L"zh-CN",
      &writeTextFormat);
  return hr;
}

HRESULT MainWindow::CreateDeviceResources() {
  HRESULT hr = S_OK;
  if (renderTarget != nullptr) {
    return S_OK;
  }
  RECT rc;
  ::GetClientRect(m_hWnd, &rc);
  D2D1_SIZE_U size = D2D1::SizeU(rc.right - rc.left, rc.bottom - rc.top);
  hr = m_pFactory->CreateHwndRenderTarget(
      D2D1::RenderTargetProperties(),
      D2D1::HwndRenderTargetProperties(m_hWnd, size), &renderTarget);
  renderTarget->SetDpi(static_cast<float>(dpiX), static_cast<float>(dpiX));
  if (SUCCEEDED(hr)) {
    hr = renderTarget->CreateSolidColorBrush(D2D1::ColorF(D2D1::ColorF::Black),
                                             &textBrush);
  }
  if (SUCCEEDED(hr)) {
    hr = renderTarget->CreateSolidColorBrush(D2D1::ColorF(0xFFC300),
                                             &borderBrush);
  }
  return hr;
}

void MainWindow::DiscardDeviceResources() {
  ///
  Free(&renderTarget);
  Free(&textBrush);
  Free(&borderBrush);
}

HRESULT MainWindow::OnRender() {
  auto hr = CreateDeviceResources();
  if (FAILED(hr)) {
    return hr;
  }
  auto dsz = renderTarget->GetSize();
  renderTarget->BeginDraw();
  renderTarget->SetTransform(D2D1::Matrix3x2F::Identity());
  renderTarget->Clear(D2D1::ColorF(D2D1::ColorF::White, 1.0f));

  renderTarget->DrawRectangle(
      D2D1::RectF(20, 10, dsz.width - 20, dsz.height - 20), borderBrush, 1.0);

  renderTarget->DrawLine(D2D1::Point2F(20, 220),
                         D2D1::Point2F(dsz.width - 20, 220), borderBrush, 1.0);

  for (const auto &label : labels) {
    if (label.empty()) {
      continue;
    }
    renderTarget->DrawTextW(label.data(), label.length(), writeTextFormat,
                            label.F(), textBrush,
                            D2D1_DRAW_TEXT_OPTIONS_ENABLE_COLOR_FONT,
                            DWRITE_MEASURING_MODE_NATURAL);
  }
  writeTextFormat->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
  hr = renderTarget->EndDraw();

  if (hr == D2DERR_RECREATE_TARGET) {
    hr = S_OK;
    DiscardDeviceResources();
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
  if (renderTarget) {
    renderTarget->Resize(D2D1::SizeU(width, height));
  }
}

HRESULT MainWindow::InitializeControl() {
  bela::error_code ec;
  if (!clangbuilder::LookupClangbuilderTarget(root, targetFile, ec)) {
    bela::BelaMessageBox(m_hWnd, L"Clangbuilder Error", ec.message.data(),
                         nullptr, bela::mbs_t::FATAL);
    return S_FALSE;
  }
  settings.Initialize(root, [this](const std::wstring &message) {
    bela::BelaMessageBox(m_hWnd, L"Unable parse settings.json", message.data(),
                         nullptr, bela::mbs_t::FATAL);
  });

  if (!InitializeElemets()) {
    bela::BelaMessageBox(m_hWnd, L"Not Found any Visual Studio",
                         L"Please check visual studio is installed", nullptr,
                         bela::mbs_t::FATAL);
  }

  for (const auto &i : search.Instances()) {
    ::SendMessage(hvsbox.hWnd, CB_ADDSTRING, 0,
                  (LPARAM)(i.DisplayName.c_str()));
  }
  auto index = search.Index();
  ::SendMessage(hvsbox.hWnd, CB_SETCURSEL, (WPARAM)(index), 0);

  for (const auto &a : tables.Targets) {
    ::SendMessage(htargetbox.hWnd, CB_ADDSTRING, 0, (LPARAM)a.data());
  }
#ifdef _M_X64
  ::SendMessage(htargetbox.hWnd, CB_SETCURSEL, 1, 0);
#else
  if (clangbuilder::IsWow64Process()) {
    ::SendMessage(htargetbox.hWnd, CB_SETCURSEL, 1, 0);
  } else {
    ::SendMessage(htargetbox.hWnd, CB_SETCURSEL, 0, 0);
  }

#endif

  for (const auto &f : tables.Configurations) {
    ::SendMessage(hconfigbox.hWnd, CB_ADDSTRING, 0, (LPARAM)f.data());
  }

  ::SendMessage(hconfigbox.hWnd, CB_SETCURSEL, 0, 0);

  for (const auto &e : tables.Engines) {
    ::SendMessage(hbuildbox.hWnd, CB_ADDSTRING, 0, (LPARAM)e.Desc.data());
  }
  ::SendMessage(hbuildbox.hWnd, CB_SETCURSEL, 0, 0);

  for (const auto &b : tables.Branches) {
    ::SendMessage(hbranchbox.hWnd, CB_ADDSTRING, 0, (LPARAM)b.data());
  }
  ::SendMessage(hbranchbox.hWnd, CB_SETCURSEL, 0, 0);

  // Button_SetCheck(hCheckLink_, 1);
  return S_OK;
}

bool UpdateFontWithNewDPI(HFONT &hFont, int dpiY) {
  if (hFont == nullptr) {
    hFont = (HFONT)GetStockObject(DEFAULT_GUI_FONT);
  }
  LOGFONTW logFont = {0};
  if (GetObjectW(hFont, sizeof(logFont), &logFont) == 0) {
    return false;
  }
  logFont.lfHeight = -MulDiv(14, dpiY, 96);
  logFont.lfWeight = FW_NORMAL;
  wcscpy_s(logFont.lfFaceName, L"Segoe UI");
  auto hNewFont = CreateFontIndirectW(&logFont);
  if (hNewFont == nullptr) {
    return false;
  }
  DeleteObject(hFont);
  hFont = hNewFont;
  return true;
}

/*
 *  Message Action Function
 */
LRESULT MainWindow::OnCreate(UINT nMsg, WPARAM wParam, LPARAM lParam,
                             BOOL &bHandle) {
  // Adjust window initialize use real DPI
  dpiX = GetDpiForWindow(m_hWnd);
  dpiY = dpiX;
  RECT rect;
  SystemParametersInfo(SPI_GETWORKAREA, 0, &rect, 0);
  int cx = rect.right - rect.left;
  auto w = MulDiv(700, dpiX, 96);
  ::SetWindowPos(m_hWnd, nullptr, (cx - w) / 2, MulDiv(100, dpiX, 96), w,
                 MulDiv(540, dpiX, 96), SWP_NOZORDER | SWP_NOACTIVATE);
  UpdateFontWithNewDPI(hFont, dpiY);

  // change UI style
  HICON hIcon = LoadIconW(hInst, MAKEINTRESOURCEW(IDI_CLANGBUILDERUI));
  SetIcon(hIcon, TRUE);
  //
  auto MakeWindow = [&](LPCWSTR lpClassName, LPCWSTR lpWindowName,
                        DWORD dwStyle, int X, int Y, int nWidth, int nHeight,
                        HMENU hMenu, Widget &w) {
    auto hw = CreateWindowExW(
        wexstyle, lpClassName, lpWindowName, dwStyle, MulDiv(X, dpiX, 96),
        MulDiv(Y, dpiY, 96), MulDiv(nWidth, dpiX, 96),
        MulDiv(nHeight, dpiY, 96), m_hWnd, hMenu, hInst, nullptr);
    if (hw == nullptr) {
      return false;
    }
    w.hWnd = hw;
    w.layout.left = X;
    w.layout.top = Y;
    w.layout.right = X + nWidth;
    w.layout.bottom = Y + nHeight;
    ::SendMessageW(hw, WM_SETFONT, (WPARAM)hFont, TRUE);
    return true;
  };

  // combobox
  MakeWindow(WC_COMBOBOXW, L"", cbstyle, 200, 20, 400, 30, nullptr, hvsbox);
  MakeWindow(WC_COMBOBOXW, L"", cbstyle, 200, 60, 400, 30, nullptr, htargetbox);
  MakeWindow(WC_COMBOBOXW, L"", cbstyle, 200, 100, 400, 30, nullptr,
             hconfigbox);
  MakeWindow(WC_COMBOBOXW, L"", chboxstyle, 200, 140, 400, 30, nullptr,
             hbranchbox);
  MakeWindow(WC_COMBOBOXW, L"", chboxstyle, 200, 180, 400, 30,
             (HMENU)IDM_ENGINE_COMBOX, hbuildbox);

  // button
  MakeWindow(WC_BUTTONW, L"Build Libcxx on Windows", chboxstyle, 200, 230, 360,
             27, nullptr, hlibcxx);
  hlibcxx.Enable(false); // disable libcxx by default
  MakeWindow(WC_BUTTONW, L"Clang/LLVM bootstrap with ThinLTO", chboxstyle, 200,
             260, 360, 27, nullptr, hlto);

  MakeWindow(WC_BUTTONW, L"SDK Compatibility (Windows 8.1 SDK) (Env)",
             chboxstyle, 200, 290, 360, 27, nullptr, hsdklow);

  MakeWindow(WC_BUTTONW, L"Create Installation Package", chboxstyle, 200, 320,
             360, 27, nullptr, hcpack);
  MakeWindow(WC_BUTTONW, L"Use Clean Environment (Env)", chboxstyle, 200, 350,
             360, 27, nullptr, hcleanenv);
  MakeWindow(WC_BUTTONW, L"Build LLDB (Visual Studio 2017 or Later)",
             chboxstyle, 200, 380, 360, 27, nullptr, hlldb);
  // Button_SetElevationRequiredState
  MakeWindow(WC_BUTTONW, L"Building", pbstyle, 200, 430, 195, 30,
             (HMENU)IDC_BUTTON_STARTTASK, hbuildtask);
  MakeWindow(WC_BUTTONW, L"Environment Console", pbstyle | BS_ICON, 405, 430,
             195, 30, (HMENU)IDC_BUTTON_STARTENV, hbuildenv);

  HMENU hSystemMenu = ::GetSystemMenu(m_hWnd, FALSE);
  InsertMenuW(hSystemMenu, SC_CLOSE, MF_ENABLED, IDM_CLANGBUILDER_ABOUT,
              L"About ClangbuilderUI\tAlt+F1");

  labels.emplace_back(30, 20, 190, 50, L"Distribution\t\U0001F19A:"); //🆚
  labels.emplace_back(30, 60, 190, 90, L"Architecture\t\U0001F4BB:"); //💻
  labels.emplace_back(30, 100, 190, 130, L"Configuration\t\u2699:");  //⚙
  labels.emplace_back(30, 140, 190, 170, L"Branches\t\t\u26A1:");     //⚡
  labels.emplace_back(30, 180, 190, 210, L"Engine\t\t\U0001f6e0:");   //🛠
  labels.emplace_back(30, 230, 190, 270, L"Build Options\t\u2611:");  //☑
  ///
  if (settings.SetWindowCompositionAttributeEnabled()) {
    if (!SetWindowCompositionAttributeImpl(m_hWnd)) {
      auto ec = bela::make_system_error_code();
      ::MessageBoxW(m_hWnd, ec.data(), L"unable set composition", MB_OK);
    }
  }
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
  dpiX = static_cast<UINT32>(LOWORD(wParam));
  dpiY = static_cast<UINT32>(HIWORD(wParam));
  auto prcNewWindow = reinterpret_cast<RECT *const>(lParam);
  // resize window with new DPI
  ::SetWindowPos(m_hWnd, nullptr, prcNewWindow->left, prcNewWindow->top,
                 prcNewWindow->right - prcNewWindow->left,
                 prcNewWindow->bottom - prcNewWindow->top,
                 SWP_NOZORDER | SWP_NOACTIVATE);
  UpdateFontWithNewDPI(hFont, dpiY);
  renderTarget->SetDpi(static_cast<float>(dpiX), static_cast<float>(dpiY));
  auto UpdateWindowPos = [&](const Widget &w) {
    ::SetWindowPos(w.hWnd, NULL, MulDiv(w.layout.left, dpiX, 96),
                   MulDiv(w.layout.top, dpiY, 96),
                   MulDiv(w.layout.right - w.layout.left, dpiX, 96),
                   MulDiv(w.layout.bottom - w.layout.top, dpiY, 96),
                   SWP_NOZORDER | SWP_NOACTIVATE);
    ::SendMessageW(w.hWnd, WM_SETFONT, (WPARAM)hFont, TRUE);
  };
  UpdateWindowPos(hvsbox);
  UpdateWindowPos(htargetbox);
  UpdateWindowPos(hconfigbox);
  UpdateWindowPos(hbranchbox);
  UpdateWindowPos(hbuildbox);
  UpdateWindowPos(hlibcxx);
  UpdateWindowPos(hlto);
  UpdateWindowPos(hsdklow);
  UpdateWindowPos(hcpack);
  UpdateWindowPos(hcleanenv);
  UpdateWindowPos(hlldb);
  UpdateWindowPos(hbuildtask);
  UpdateWindowPos(hbuildenv);
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
  bela::BelaMessageBox(m_hWnd, L"About Clangbuilder", CLANGBUILDER_APPVERSION,
                       CLANGBUILDER_APPLINK, bela::mbs_t::ABOUT);
  return S_OK;
}

/*
 * ClangbuilderTarget.ps1
 */

LRESULT MainWindow::OnChangeEngine(WORD wNotifyCode, WORD wID, HWND hWndCtl,
                                   BOOL &bHandled) {
  if (wNotifyCode == CBN_SELCHANGE) {
    auto N = ComboBox_GetCurSel(hbuildbox.hWnd);
    hlibcxx.Enable(N == 1 || N == 3);
  }
  return S_OK;
}
