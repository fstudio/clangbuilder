//
//
//
//

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <atlbase.h>
#include <atlwin.h>
#include <atlctl.h>
#include <string>
#include <d2d1.h>
#include <d2d1helper.h>
#include <dwrite.h>
#include <wincodec.h>
#include <vector>
#include "Clangbuilder.h"
#include "Resource.h"

#ifndef SYSCOMMAND_ID_HANDLER
#define SYSCOMMAND_ID_HANDLER(id, func) \
	if(uMsg == WM_SYSCOMMAND && id == LOWORD(wParam)) \
				{ \
		bHandled = TRUE; \
		lResult = func(HIWORD(wParam), LOWORD(wParam), (HWND)lParam, bHandled); \
		if(bHandled) \
			return TRUE; \
				}
#endif

#define CLANGBUILDERUI_MAINWINDOW _T("Clangbuilder.Render.UI.Window")
typedef CWinTraits<WS_OVERLAPPEDWINDOW, WS_EX_APPWINDOW | WS_EX_WINDOWEDGE> CMetroWindowTraits;

struct KryceLabel {
	KryceLabel(LONG left, LONG top, LONG right, LONG bottom, const wchar_t *text) :text(text)
	{
		layout.left = left;
		layout.top = top;
		layout.right = right;
		layout.bottom = bottom;
	}
	RECT layout;
	std::wstring text;
};


class CDPI;
class MainWindow :public CWindowImpl<MainWindow, CWindow, CMetroWindowTraits> {
public:
	MainWindow();
	~MainWindow();
	LRESULT InitializeWindow();
	DECLARE_WND_CLASS(CLANGBUILDERUI_MAINWINDOW)
	BEGIN_MSG_MAP(MainWindow)
		MESSAGE_HANDLER(WM_CREATE, OnCreate)
		MESSAGE_HANDLER(WM_CLOSE, OnClose)
		MESSAGE_HANDLER(WM_DESTROY, OnDestroy)
		MESSAGE_HANDLER(WM_SIZE, OnSize)
		MESSAGE_HANDLER(WM_PAINT, OnPaint)
		MESSAGE_HANDLER(WM_CTLCOLORSTATIC, OnCtlColorStatic)
		SYSCOMMAND_ID_HANDLER(IDM_CLANGBUILDER_ABOUT,OnSysMemuAbout)
		COMMAND_ID_HANDLER(IDC_BUTTON_STARTTASK,OnBuildNow)
		COMMAND_ID_HANDLER(IDC_BUTTON_STARTENV,OnStartupEnv)
	END_MSG_MAP()
	LRESULT OnCreate(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle);
	LRESULT OnDestroy(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle);
	LRESULT OnClose(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle);
	LRESULT OnSize(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle);
	LRESULT OnPaint(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle);
	LRESULT OnCtlColorStatic(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle);
	LRESULT OnSysMemuAbout(WORD wNotifyCode, WORD wID, HWND hWndCtl, BOOL& bHandled);
	LRESULT OnBuildNow(WORD wNotifyCode, WORD wID, HWND hWndCtl, BOOL& bHandled);
	LRESULT OnStartupEnv(WORD wNotifyCode, WORD wID, HWND hWndCtl, BOOL& bHandled);
	////
private:
	CDPI *g_Dpi;
	ID2D1Factory *m_pFactory;
	ID2D1HwndRenderTarget* m_pHwndRenderTarget;
	ID2D1SolidColorBrush* m_pBasicTextBrush;
	ID2D1SolidColorBrush* m_AreaBorderBrush;
	IDWriteTextFormat* m_pWriteTextFormat;
	IDWriteFactory* m_pWriteFactory;

	HRESULT CreateDeviceIndependentResources();
	HRESULT Initialize();
	HRESULT InitializeControl();
	HRESULT CreateDeviceResources();
	void DiscardDeviceResources();
	HRESULT OnRender();
	D2D1_SIZE_U CalculateD2DWindowSize();
	void OnResize(
		UINT width,
		UINT height
		);
	HWND hCobVS_;
	HWND hCobArch_;
	HWND hCobFlavor_;
	HWND hCheckBoostrap_;
	HWND hCheckReleased_;
	HWND hCheckPackaged_;
	HWND hCheckCleanEnv_;
	HWND hCheckLink_;
	HWND hCheckNMake_;
	HWND hCheckLLDB_;
	HWND hButtonTask_;
	HWND hButtonEnv_;
	std::vector<KryceLabel> label_;
	std::vector<VisualStudioIndex> index_;
};
#endif
