//

#ifndef CBUI_APPUI_HPP
#define CBUI_APPUI_HPP

#include <atlbase.h>
#include <atlwin.h>
#include <atlctl.h>
#include <string>
#include <d2d1.h>
#include <d2d1helper.h>
#include <dwrite.h>
#include <wincodec.h>
#include <vector>
#include <string_view>
#include <comutils.hpp>
#include "../res/appuires.h"
#include "app.hpp"

#ifndef SYSCOMMAND_ID_HANDLER
#define SYSCOMMAND_ID_HANDLER(id, func)                                        \
  if (uMsg == WM_SYSCOMMAND && id == LOWORD(wParam)) {                         \
    bHandled = TRUE;                                                           \
    lResult = func(HIWORD(wParam), LOWORD(wParam), (HWND)lParam, bHandled);    \
    if (bHandled)                                                              \
      return TRUE;                                                             \
  }
#endif

constexpr const wchar_t *AppWindowName = L"Clangbuilder.Render.UI.Window";

using WindowTraits =
    CWinTraits<WS_OVERLAPPEDWINDOW, WS_EX_APPWINDOW | WS_EX_WINDOWEDGE>;

struct KryceLabel {
  KryceLabel(LONG left, LONG top, LONG right, LONG bottom, const wchar_t *text)
      : text(text) {
    layout.left = left;
    layout.top = top;
    layout.right = right;
    layout.bottom = bottom;
  }
  RECT layout;
  D2D1_RECT_F F() const {
    return D2D1::RectF((float)layout.left, (float)layout.top,
                       (float)layout.right, (float)layout.bottom);
  }
  std::wstring text;
  const wchar_t *data() const { return text.data(); }
  UINT32 length() const { return static_cast<UINT32>(text.size()); }
  bool empty() const { return text.empty(); }
};

struct EngineItem {
  EngineItem(std::wstring_view d, std::wstring_view v) : Desc(d), Value(v) {}
  std::wstring Desc;
  std::wstring Value;
};

struct ClangbuilderTable {
  std::vector<std::wstring> Targets;
  std::vector<std::wstring> Configurations;
  std::vector<EngineItem> Engines;
  std::vector<std::wstring> Branches;
  ClangbuilderTable &AddEngine(std::wstring_view d, std::wstring_view v) {
    Engines.push_back(EngineItem(d, v));
    return *this;
  }
};

struct Widget {
  HWND hWnd{nullptr};
  RECT layout;
  bool Enable(bool enable) {
    return ::EnableWindow(hWnd, enable ? TRUE : FALSE) == TRUE;
  }
};

class MainWindow : public CWindowImpl<MainWindow, CWindow, WindowTraits> {
public:
  MainWindow();
  ~MainWindow();
  LRESULT InitializeWindow();
  DECLARE_WND_CLASS(AppWindowName)
  BEGIN_MSG_MAP(MainWindow)
  MESSAGE_HANDLER(WM_CREATE, OnCreate)
  MESSAGE_HANDLER(WM_CLOSE, OnClose)
  MESSAGE_HANDLER(WM_DESTROY, OnDestroy)
  MESSAGE_HANDLER(WM_SIZE, OnSize)
  MESSAGE_HANDLER(WM_DPICHANGED, OnDpiChanged)
  MESSAGE_HANDLER(WM_PAINT, OnPaint)
  MESSAGE_HANDLER(WM_CTLCOLORSTATIC, OnCtlColorStatic)
  SYSCOMMAND_ID_HANDLER(IDM_CLANGBUILDER_ABOUT, OnSysMemuAbout)
  COMMAND_ID_HANDLER(IDC_BUTTON_STARTTASK, OnBuildNow)
  COMMAND_ID_HANDLER(IDC_BUTTON_STARTENV, OnStartupEnv)
  COMMAND_ID_HANDLER(IDM_ENGINE_COMBOX, OnChangeEngine)
  END_MSG_MAP()
  LRESULT OnCreate(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle);
  LRESULT OnDestroy(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle);
  LRESULT OnClose(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle);
  LRESULT OnSize(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle);
  LRESULT OnDpiChanged(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle);
  LRESULT OnPaint(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle);
  LRESULT OnCtlColorStatic(UINT nMsg, WPARAM wParam, LPARAM lParam,
                           BOOL &bHandle);
  LRESULT OnSysMemuAbout(WORD wNotifyCode, WORD wID, HWND hWndCtl,
                         BOOL &bHandled);
  LRESULT OnBuildNow(WORD wNotifyCode, WORD wID, HWND hWndCtl, BOOL &bHandled);
  LRESULT OnStartupEnv(WORD wNotifyCode, WORD wID, HWND hWndCtl,
                       BOOL &bHandled);
  LRESULT OnChangeEngine(WORD wNotifyCode, WORD wID, HWND hWndCtl,
                         BOOL &bHandled);
  ////
private:
  ID2D1Factory *m_pFactory{nullptr};
  IDWriteTextFormat *writeTextFormat{nullptr};
  IDWriteFactory *writeFactory{nullptr};
  //
  ID2D1HwndRenderTarget *renderTarget{nullptr};
  ID2D1SolidColorBrush *textBrush{nullptr};
  ID2D1SolidColorBrush *borderBrush{nullptr};

  int dpiX{0};
  int dpiY{0};
  HRESULT CreateDeviceIndependentResources();
  HRESULT InitializeControl();
  HRESULT CreateDeviceResources();
  void DiscardDeviceResources();
  HRESULT OnRender();
  D2D1_SIZE_U CalculateD2DWindowSize();
  void OnResize(UINT width, UINT height);
  ///////////
  bool InitializeElemets();
  /// member
  HINSTANCE hInst{nullptr};
  HFONT hFont{nullptr};
  // combobox
  Widget hvsbox;
  Widget htargetbox;
  Widget hconfigbox;
  Widget hbranchbox;
  Widget hbuildbox;
  // checkbox
  Widget hlibcxx;
  Widget hlto;
  Widget hsdklow;
  Widget hcpack;
  Widget hcleanenv;
  Widget hlldb;
  // button about
  Widget hbuildtask;
  Widget hbuildenv;
  Settings settings;
  std::vector<KryceLabel> labels;
  std::wstring targetFile;
  std::wstring root;
  ClangbuilderTable tables;
  VisualStudioSeacher search;
};
#endif
