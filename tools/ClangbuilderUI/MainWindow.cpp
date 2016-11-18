#include "stdafx.h"
#include <cassert>
#include <Prsht.h>
#include <CommCtrl.h>
#include <Shlwapi.h>
#include <Shellapi.h>
#include  <Shlobj.h>
#include <PathCch.h>
#include <ShellScalingAPI.h>
#include <array>
#include "MainWindow.h"
#include "MessageWindow.h"

#ifndef HINST_THISCOMPONENT
EXTERN_C IMAGE_DOS_HEADER __ImageBase;
#define HINST_THISCOMPONENT ((HINSTANCE)&__ImageBase)
#endif

#define WS_NORESIZEWINDOW (WS_OVERLAPPED     | \
                             WS_CAPTION        | \
                             WS_SYSMENU        | \
                             WS_MINIMIZEBOX )

template<class Interface>
inline void
SafeRelease(
Interface **ppInterfaceToRelease
)
{
	if (*ppInterfaceToRelease != NULL) {
		(*ppInterfaceToRelease)->Release();

		(*ppInterfaceToRelease) = NULL;
	}
}

int RectHeight(RECT Rect)
{
	return Rect.bottom - Rect.top;
}

int RectWidth(RECT Rect)
{
	return Rect.right - Rect.left;
}

class CDPI {
public:
	CDPI()
	{
		m_nScaleFactor = 0;
		m_nScaleFactorSDA = 0;
		m_Awareness = PROCESS_DPI_UNAWARE;
	}

	int  Scale(int x)
	{
		// DPI Unaware:  Return the input value with no scaling.
		// These apps are always virtualized to 96 DPI and scaled by the system for the DPI of the monitor where shown.
		if (m_Awareness == PROCESS_DPI_UNAWARE) {
			return x;
		}

		// System DPI Aware:  Return the input value scaled by the factor determined by the system DPI when the app was launched.
		// These apps render themselves according to the DPI of the display where they are launched, and they expect that scaling
		// to remain constant for all displays on the system.
		// These apps are scaled up or down when moved to a display with a different DPI from the system DPI.
		if (m_Awareness == PROCESS_SYSTEM_DPI_AWARE) {
			return MulDiv(x, m_nScaleFactorSDA, 100);
		}

		// Per-Monitor DPI Aware:  Return the input value scaled by the factor for the display which contains most of the window.
		// These apps render themselves for any DPI, and re-render when the DPI changes (as indicated by the WM_DPICHANGED window message).
		return MulDiv(x, m_nScaleFactor, 100);
	}

	UINT GetScale()
	{
		if (m_Awareness == PROCESS_DPI_UNAWARE) {
			return 100;
		}

		if (m_Awareness == PROCESS_SYSTEM_DPI_AWARE) {
			return m_nScaleFactorSDA;
		}

		return m_nScaleFactor;
	}

	void SetScale(__in UINT iDPI)
	{
		m_nScaleFactor = MulDiv(iDPI, 100, 96);
		if (m_nScaleFactorSDA == 0) {
			m_nScaleFactorSDA = m_nScaleFactor;  // Save the first scale factor, which is all that SDA apps know about
		}
		return;
	}

	PROCESS_DPI_AWARENESS GetAwareness()
	{
		HANDLE hProcess;
		hProcess = OpenProcess(PROCESS_ALL_ACCESS, false, GetCurrentProcessId());
		GetProcessDpiAwareness(hProcess, &m_Awareness);
		return m_Awareness;
	}

	void SetAwareness(PROCESS_DPI_AWARENESS awareness)
	{
		HRESULT hr = E_FAIL;
		hr = SetProcessDpiAwareness(awareness);
		//auto l = E_INVALIDARG;
		if (hr == S_OK) {
			m_Awareness = awareness;
		} else {
			MessageBoxW(NULL,L"SetProcessDpiAwareness Error", L"Error", MB_OK);
		}
		return;
	}

	// Scale rectangle from raw pixels to relative pixels.
	void ScaleRect(__inout RECT *pRect)
	{
		pRect->left = Scale(pRect->left);
		pRect->right = Scale(pRect->right);
		pRect->top = Scale(pRect->top);
		pRect->bottom = Scale(pRect->bottom);
	}

	// Scale Point from raw pixels to relative pixels.
	void ScalePoint(__inout POINT *pPoint)
	{
		pPoint->x = Scale(pPoint->x);
		pPoint->y = Scale(pPoint->y);
	}

private:
	UINT m_nScaleFactor;
	UINT m_nScaleFactorSDA;
	PROCESS_DPI_AWARENESS m_Awareness;
};


const wchar_t *ArchList[] = {
	L"x86",
	L"x64",
	L"ARM",
	L"ARM64"
};

const wchar_t *FlavorList[] = {
	L"Release",
	L"MinSizeRel",
	L"RelWithDebInfo",
	L"Debug"
};
/*
* Resources Initialize and Release
*/

MainWindow::MainWindow()
	:m_pFactory(nullptr),
	m_pHwndRenderTarget(nullptr),
	m_pBasicTextBrush(nullptr),
	m_AreaBorderBrush(nullptr),
	m_pWriteFactory(nullptr),
	m_pWriteTextFormat(nullptr)
{
	g_Dpi = new CDPI();
	g_Dpi->SetAwareness(PROCESS_PER_MONITOR_DPI_AWARE);
}
MainWindow::~MainWindow()
{
	if (g_Dpi) {
		delete g_Dpi;
	}
	SafeRelease(&m_pWriteTextFormat);
	SafeRelease(&m_pWriteFactory);
	SafeRelease(&m_pBasicTextBrush);
	SafeRelease(&m_AreaBorderBrush);
	SafeRelease(&m_pHwndRenderTarget);
	SafeRelease(&m_pFactory);
}

LRESULT MainWindow::InitializeWindow()
{
	HMONITOR hMonitor;
	POINT    pt;
	UINT     dpix = 0, dpiy = 0;
	HRESULT  hr = E_FAIL;

	// Get the DPI for the main monitor, and set the scaling factor
	pt.x = 1;
	pt.y = 1;
	hMonitor = MonitorFromPoint(pt, MONITOR_DEFAULTTONEAREST);
	hr = GetDpiForMonitor(hMonitor, MDT_EFFECTIVE_DPI, &dpix, &dpiy);

	if (hr != S_OK) {
		::MessageBox(NULL, (LPCWSTR)L"GetDpiForMonitor failed", (LPCWSTR)L"Notification", MB_OK);
		return FALSE;
	}
	g_Dpi->SetScale(dpix);
	RECT layout = { g_Dpi->Scale(100), g_Dpi->Scale(100), g_Dpi->Scale(800), g_Dpi->Scale(640) };
	Create(nullptr, layout, L"Clangbuilder Environment Utility",
		   WS_NORESIZEWINDOW,
		   WS_EX_APPWINDOW | WS_EX_WINDOWEDGE);
	return S_OK;
}


///
HRESULT MainWindow::CreateDeviceIndependentResources()
{
	HRESULT hr = S_OK;
	hr = D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &m_pFactory);
	return hr;
}
HRESULT MainWindow::Initialize()
{
	auto hr = CreateDeviceIndependentResources();
	FLOAT dpiX, dpiY;
	m_pFactory->GetDesktopDpi(&dpiX, &dpiY);
	return hr;
}
HRESULT MainWindow::CreateDeviceResources()
{
	HRESULT hr = S_OK;

	if (!m_pHwndRenderTarget) {
		RECT rc;
		::GetClientRect(m_hWnd, &rc);
		D2D1_SIZE_U size = D2D1::SizeU(
			rc.right - rc.left,
			rc.bottom - rc.top
			);
		hr = m_pFactory->CreateHwndRenderTarget(
			D2D1::RenderTargetProperties(),
			D2D1::HwndRenderTargetProperties(m_hWnd, size),
			&m_pHwndRenderTarget
			);
		if (SUCCEEDED(hr)) {
			hr = m_pHwndRenderTarget->CreateSolidColorBrush(
				D2D1::ColorF(D2D1::ColorF::Black),
				&m_pBasicTextBrush
				);
		}
		if (SUCCEEDED(hr)) {
			hr = m_pHwndRenderTarget->CreateSolidColorBrush(
				D2D1::ColorF(0xFFC300),
				&m_AreaBorderBrush
				);
		}
	}
	return hr;

}
void MainWindow::DiscardDeviceResources()
{
	SafeRelease(&m_pBasicTextBrush);
}
HRESULT MainWindow::OnRender()
{
	auto hr = CreateDeviceResources();
	hr = DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED,
							 __uuidof(IDWriteFactory),
							 reinterpret_cast<IUnknown**>(&m_pWriteFactory));
	if (hr != S_OK) return hr;
	hr = m_pWriteFactory->CreateTextFormat(
		L"Segoe UI",
		NULL,
		DWRITE_FONT_WEIGHT_NORMAL,
		DWRITE_FONT_STYLE_NORMAL,
		DWRITE_FONT_STRETCH_NORMAL,
		12.0f * 96.0f / 72.0f,
		L"zh-CN",
		&m_pWriteTextFormat);
#pragma warning(disable:4244)
#pragma warning(disable:4267)
	if (SUCCEEDED(hr)) {
		RECT rect;
		GetWindowRect(&rect);
		m_pHwndRenderTarget->BeginDraw();
		m_pHwndRenderTarget->SetTransform(D2D1::Matrix3x2F::Identity());
		m_pHwndRenderTarget->Clear(D2D1::ColorF(D2D1::ColorF::White, 1.0f));

		m_pHwndRenderTarget->DrawRectangle(D2D1::RectF(20, 10, rect.right - rect.left - 40, 150), m_AreaBorderBrush, 1.0);
		m_pHwndRenderTarget->DrawRectangle(D2D1::RectF(20, 150, rect.right - rect.left - 40, 390), m_AreaBorderBrush, 1.0);

		for (auto &label : label_) {
			if (label.text.empty())
				continue;
			m_pHwndRenderTarget->DrawTextW(label.text.c_str(),
										   label.text.size(),
										   m_pWriteTextFormat,
										   D2D1::RectF(label.layout.left, label.layout.top, label.layout.right, label.layout.bottom),
										   m_pBasicTextBrush,
										   D2D1_DRAW_TEXT_OPTIONS_NONE, DWRITE_MEASURING_MODE_NATURAL);
		}
		m_pWriteTextFormat->SetTextAlignment(DWRITE_TEXT_ALIGNMENT_CENTER);
		hr = m_pHwndRenderTarget->EndDraw();
	}
#pragma warning(default:4244)
#pragma warning(default:4267)	
	if (hr == D2DERR_RECREATE_TARGET) {
		hr = S_OK;
		DiscardDeviceResources();
		::InvalidateRect(m_hWnd, nullptr, FALSE);
	}
	return hr;
}
D2D1_SIZE_U MainWindow::CalculateD2DWindowSize()
{
	RECT rc;
	::GetClientRect(m_hWnd, &rc);

	D2D1_SIZE_U d2dWindowSize = { 0 };
	d2dWindowSize.width = rc.right;
	d2dWindowSize.height = rc.bottom;

	return d2dWindowSize;
}

void MainWindow::OnResize(
	UINT width,
	UINT height
	)
{
	if (m_pHwndRenderTarget) {
		m_pHwndRenderTarget->Resize(D2D1::SizeU(width, height));
	}
}

#define WINDOWEXSTYLE WS_EX_LEFT | WS_EX_LTRREADING | WS_EX_RIGHTSCROLLBAR | WS_EX_NOPARENTNOTIFY
#define COMBOBOXSTYLE WS_CHILDWINDOW | WS_CLIPSIBLINGS | WS_VISIBLE | WS_TABSTOP | CBS_DROPDOWNLIST  | CBS_HASSTRINGS
#define CHECKBOXSTYLE BS_PUSHBUTTON | BS_TEXT | BS_DEFPUSHBUTTON | BS_CHECKBOX | BS_AUTOCHECKBOX | WS_CHILD | WS_OVERLAPPED | WS_VISIBLE
#define PUSHBUTTONSTYLE BS_PUSHBUTTON | BS_TEXT | WS_CHILD | WS_OVERLAPPED | WS_VISIBLE

HRESULT MainWindow::InitializeControl()
{
	if (!VisualStudioSearch(index_)) {
		return S_FALSE;
	}
	assert(hCobVS_);
	assert(hCobArch_);
	assert(hCobFlavor_);
	assert(hCheckBoostrap_);
	assert(hCheckReleased_);
	assert(hCheckPackaged_);
	assert(hCheckCleanEnv_);
	assert(hCheckLink_);
	assert(hCheckNMake_);
	assert(hCheckLLDB_);
	assert(hButtonTask_);
	assert(hButtonEnv_);
	for (auto &i : index_) {
		::SendMessage(hCobVS_, CB_ADDSTRING, 0, (LPARAM)(i.name.c_str()));
	}
	::SendMessage(hCobVS_, CB_SETCURSEL, index_.size() - 1, 0);
	for (auto &a : ArchList) {
		::SendMessage(hCobArch_, CB_ADDSTRING, 0, (LPARAM)a);
	}
#ifdef _M_X64
	::SendMessage(hCobArch_, CB_SETCURSEL, 1, 0);
#else
	::SendMessage(hCobArch_, CB_SETCURSEL, 0, 0);
#endif

	for (auto &f : FlavorList) {
		::SendMessage(hCobFlavor_, CB_ADDSTRING, 0, (LPARAM)f);
	}

	::SendMessage(hCobFlavor_, CB_SETCURSEL, 0, 0);
	Button_SetCheck(hCheckLink_, 1);
	return S_OK;
}


/*
*  Message Action Function
*/
LRESULT MainWindow::OnCreate(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle)
{
	auto hr = Initialize();
	if (hr != S_OK) {
		::MessageBoxW(nullptr, L"Initialize() failed", L"Fatal error", MB_OK | MB_ICONSTOP);
		std::terminate();
		return S_FALSE;
	}
	HICON hIcon = LoadIconW(GetModuleHandleW(nullptr), MAKEINTRESOURCEW(IDI_CLANGBUILDERUI));
	SetIcon(hIcon, TRUE);
	HFONT hFont = (HFONT)GetStockObject(DEFAULT_GUI_FONT);
	LOGFONTW logFont = { 0 };
	GetObjectW(hFont, sizeof(logFont), &logFont);
	DeleteObject(hFont);
	hFont = NULL;
	logFont.lfHeight = 19;
	logFont.lfWeight = FW_NORMAL;
	wcscpy_s(logFont.lfFaceName, L"Segoe UI");
	hFont = CreateFontIndirectW(&logFont);
	auto LambdaCreateWindow = [&](LPCWSTR lpClassName, LPCWSTR lpWindowName, DWORD dwStyle,
								  int X, int Y, int nWidth, int nHeight, HMENU hMenu)->HWND{
		auto hw = CreateWindowExW(WINDOWEXSTYLE, lpClassName, lpWindowName,
								  dwStyle, X, Y, nWidth, nHeight, m_hWnd, hMenu, HINST_THISCOMPONENT, nullptr);
		if (hw) {
			::SendMessageW(hw, WM_SETFONT, (WPARAM)hFont, lParam);
		}
		return hw;
	};
	hCobVS_ = LambdaCreateWindow(WC_COMBOBOXW, L"", COMBOBOXSTYLE, 200, 20, 400, 30, nullptr);
	hCobArch_ = LambdaCreateWindow(WC_COMBOBOXW, L"", COMBOBOXSTYLE, 200, 60, 400, 30, nullptr);
	hCobFlavor_ = LambdaCreateWindow(WC_COMBOBOXW, L"", COMBOBOXSTYLE, 200, 100, 400, 30, nullptr);
	hCheckBoostrap_ = LambdaCreateWindow(WC_BUTTONW, L"Clang Boostrap", CHECKBOXSTYLE, 200, 160, 360, 27, nullptr);
	hCheckReleased_ = LambdaCreateWindow(WC_BUTTONW, L"Released Revision", CHECKBOXSTYLE, 200, 190, 360, 27, nullptr);
	hCheckPackaged_ = LambdaCreateWindow(WC_BUTTONW, L"Make installation package", CHECKBOXSTYLE, 200, 220, 360, 27, nullptr);
	hCheckCleanEnv_ = LambdaCreateWindow(WC_BUTTONW, L"Use Clean Environment", CHECKBOXSTYLE, 200, 250, 360, 27, nullptr);
	hCheckLink_ = LambdaCreateWindow(WC_BUTTONW, L"Link Static Runtime Library", CHECKBOXSTYLE, 200, 280, 360, 27, nullptr);
	hCheckNMake_ = LambdaCreateWindow(WC_BUTTONW, L"Use NMake Makefiles", CHECKBOXSTYLE, 200, 310, 360, 27, nullptr);
	hCheckLLDB_ = LambdaCreateWindow(WC_BUTTONW, L"Build LLDB (Visual Studio 2015 or Later)", CHECKBOXSTYLE, 200, 340, 360, 27, nullptr);
	//Button_SetElevationRequiredState
	hButtonTask_ = LambdaCreateWindow(WC_BUTTONW, L"Build Now", PUSHBUTTONSTYLE, 200, 420, 195, 30, (HMENU)IDC_BUTTON_STARTTASK);
	hButtonEnv_ = LambdaCreateWindow(WC_BUTTONW, L"Startup Env", PUSHBUTTONSTYLE | BS_ICON, 410, 420, 195, 30, (HMENU)IDC_BUTTON_STARTENV);

	HMENU hSystemMenu = ::GetSystemMenu(m_hWnd, FALSE);
	InsertMenuW(hSystemMenu, SC_CLOSE, MF_ENABLED, IDM_CLANGBUILDER_ABOUT, L"About ClangbuilderUI\tAlt+F1");

	label_.push_back(KryceLabel(30, 20, 190, 50, L"Visual Studio\t\xD83C\xDD9A:"));
	label_.push_back(KryceLabel(30, 60, 190, 90, L"Address Mode\t\xD83D\xDEE0:"));
	label_.push_back(KryceLabel(30, 100, 190, 130, L"Configuration\t\x2699:"));
	label_.push_back(KryceLabel(30, 160, 190, 200, L"Compile Switch\t\xD83D\xDCE6:"));
	///
	if (!InitializeControl()) {

	}
	//DeleteObject(hFont);
	return S_OK;
}
LRESULT MainWindow::OnDestroy(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle)
{
	PostQuitMessage(0);
	return S_OK;
}
LRESULT MainWindow::OnClose(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle)
{
	::DestroyWindow(m_hWnd);
	return S_OK;
}
LRESULT MainWindow::OnSize(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle)
{
	UINT width = LOWORD(lParam);
	UINT height = HIWORD(lParam);
	OnResize(width, height);
	return S_OK;
}
LRESULT MainWindow::OnPaint(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle)
{
	LRESULT hr = S_OK;
	PAINTSTRUCT ps;
	BeginPaint(&ps);
	/// if auto return OnRender(),CPU usage is too high
	hr = OnRender();
	EndPaint(&ps);
	return hr;
}

LRESULT MainWindow::OnCtlColorStatic(UINT nMsg, WPARAM wParam, LPARAM lParam, BOOL &bHandle)
{
	return S_OK;
}

LRESULT MainWindow::OnSysMemuAbout(WORD wNotifyCode, WORD wID, HWND hWndCtl, BOOL& bHandled)
{
	MessageWindowEx(
		m_hWnd,
		L"About Clangbuilder",
		L"Prerelease: 1.0.0.0\nCopyright \xA9 2016, Force Charlie. All Rights Reserved.",
		L"For more information about this tool.\nVisit: <a href=\"http://forcemz.net/\">forcemz.net</a>",
		kAboutWindow);
	return S_OK;
}
/*
* ClangBuilderEnvironment.ps1
* ClangBuilderManager.ps1
* ClangBuilderBootstrap.ps1
*/
bool SearchClangbuilderPsEngine(std::wstring &psfile, const wchar_t *name)
{
	std::array<wchar_t, PATHCCH_MAX_CCH> engine_;
	GetModuleFileNameW(HINST_THISCOMPONENT, engine_.data(), PATHCCH_MAX_CCH);
	std::wstring tmpfile;
	for (int i = 0; i < 5; i++) {
		if (!PathRemoveFileSpecW(engine_.data())) {
			return false;
		}
		tmpfile.assign(engine_.data());
		tmpfile.append(L"\\bin\\").append(name);
		if (PathFileExistsW(tmpfile.c_str())) {
			psfile.assign(std::move(tmpfile));
			return true;
		}
	}
	return false;
}

bool InitializeSearchPowershell(std::wstring &ps)
{
	WCHAR pszPath[MAX_PATH]; /// by default , System Dir Length <260
	if (SHGetFolderPathW(nullptr, CSIDL_SYSTEM, nullptr, 0, pszPath) != S_OK) {
		return false;
	}
	ps.assign(pszPath);
	ps.append(L"\\WindowsPowerShell\\v1.0\\powershell.exe");
	return true;
}

bool PsCreateProcess(LPWSTR pszCommand)
{
	PROCESS_INFORMATION pi;
	STARTUPINFO si;
	ZeroMemory(&si, sizeof(si));
	ZeroMemory(&pi, sizeof(pi));
	si.cb = sizeof(si);
	si.dwFlags = STARTF_USESHOWWINDOW;
	si.wShowWindow = SW_SHOW;
	if (CreateProcessW(nullptr, pszCommand, NULL, NULL, FALSE,
		CREATE_NEW_CONSOLE | NORMAL_PRIORITY_CLASS, NULL, NULL,
		&si, &pi)) {
		CloseHandle(pi.hThread);
		CloseHandle(pi.hProcess);
		return true;
	}
	return false;
}

LPWSTR FormatMessageInternal()
{
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

LRESULT MainWindow::OnBuildNow(WORD wNotifyCode, WORD wID, HWND hWndCtl, BOOL& bHandled)
{
	std::wstring Command;
	if (!InitializeSearchPowershell(Command)) {
		MessageWindowEx(
			m_hWnd,
			L"Search PowerShell Error",
			L"Please check PowerShell",
			nullptr,
			kFatalWindow);
		return S_FALSE;
	}
	std::wstring engine_;
	if (Button_GetCheck(hCheckBoostrap_) == BST_CHECKED) {
		if (!SearchClangbuilderPsEngine(engine_, L"ClangBuilderBootstrap.ps1")) {
			MessageWindowEx(
				m_hWnd,
				L"Not Found Clangbuilder Engine",
				L"Not Found ClangBuilderBootstrap.ps1",
				nullptr, kFatalWindow);
			return false;
		}
	} else {
		if (!SearchClangbuilderPsEngine(engine_, L"ClangBuilderManager.ps1")) {
			MessageWindowEx(
				m_hWnd,
				L"Not Found Clangbuilder Engine",
				L"Not Found ClangBuilderManager.ps1",
				nullptr, kFatalWindow);
			return false;
		}
	}
	Command.append(L" -NoLogo -NoExit   -File \"").append(engine_).push_back('"');
	auto vsindex_ = ComboBox_GetCurSel(hCobVS_);
	if (vsindex_ < 0 || index_.size() <= (size_t)vsindex_) {
		return S_FALSE;
	}
	auto archindex_ = ComboBox_GetCurSel(hCobArch_);
	if (archindex_ < 0 || sizeof(ArchList) <= archindex_) {
		return S_FALSE;
	}
	if (index_[vsindex_].version <= 140) {
		if (archindex_ >= 3) {
			MessageWindowEx(
				m_hWnd,
				L"Not Support Architecture",
				L"Build ARM64 Require Visual Studio 15 or Later",
				nullptr, kFatalWindow);
			return S_FALSE;
		}
	}
	auto flavor_ = ComboBox_GetCurSel(hCobFlavor_);
	if (flavor_ < 0 || sizeof(FlavorList) <= flavor_) {
		return S_FALSE;
	}

	Command.append(L" -VisualStudio ").append(std::to_wstring(index_[vsindex_].version));
	Command.append(L" -Arch ").append(ArchList[archindex_]);
	Command.append(L" -Flavor ").append(FlavorList[flavor_]);
	///
	if (Button_GetCheck(hCheckReleased_) == BST_CHECKED) {
		Command.append(L" -Released");
	}

	if (Button_GetCheck(hCheckPackaged_) == BST_CHECKED) {
		Command.append(L" -Install");
	}

	if (Button_GetCheck(hCheckLink_) == BST_CHECKED) {
		Command.append(L" -Static");
	}

	if (Button_GetCheck(hCheckNMake_) == BST_CHECKED) {
		Command.append(L" -NMake");
	}

	if (Button_GetCheck(hCheckLLDB_) == BST_CHECKED) {
		Command.append(L" -LLDB");
	}

	if (Button_GetCheck(hCheckCleanEnv_) == BST_CHECKED) {
		Command.append(L" -Clear");
	}
	if (!PsCreateProcess(&Command[0])) {
		////
		auto errmsg = FormatMessageInternal();
		if (errmsg) {
			MessageWindowEx(
				m_hWnd,
				L"CreateProcess failed",
				errmsg,
				nullptr, kFatalWindow);
			LocalFree(errmsg);
		}
	}
	return S_OK;
}
LRESULT MainWindow::OnStartupEnv(WORD wNotifyCode, WORD wID, HWND hWndCtl, BOOL& bHandled)
{
	std::wstring Command;
	if (!InitializeSearchPowershell(Command)) {
		MessageWindowEx(
			m_hWnd,
			L"Search PowerShell Error",
			L"Please check PowerShell",
			nullptr,
			kFatalWindow);
		return S_FALSE;
	}
	std::wstring engine_;
	if (!SearchClangbuilderPsEngine(engine_, L"ClangBuilderEnvironment.ps1")) {
		MessageWindowEx(
			m_hWnd,
			L"Not Found Clangbuilder Engine",
			L"Not Found ClangBuilderEnvironment.ps1",
			nullptr, kFatalWindow);
		return false;
	}
	Command.append(L" -NoLogo -NoExit   -File \"").append(engine_).push_back('"');
	auto vsindex_ = ComboBox_GetCurSel(hCobVS_);
	if (vsindex_ < 0 || index_.size() <= (size_t)vsindex_) {
		return S_FALSE;
	}
	auto archindex_ = ComboBox_GetCurSel(hCobArch_);
	if (archindex_ < 0 || sizeof(ArchList) <= archindex_) {
		return S_FALSE;
	}
	if (index_[vsindex_].version <= 140) {
		if (archindex_ >= 3) {
			MessageWindowEx(
				m_hWnd,
				L"Not Support Architecture",
				L"Build ARM64 Require Visual Studio 15 or Later",
				nullptr, kFatalWindow);
			return S_FALSE;
		}
	}
	Command.append(L" -VisualStudio ").append(std::to_wstring(index_[vsindex_].version));
	Command.append(L" -Arch ").append(ArchList[archindex_]);

	// Search File
	if (Button_GetCheck(hCheckCleanEnv_) == BST_CHECKED) {
		Command.append(L" -Clear");
	}
	if (!PsCreateProcess(&Command[0])) {
		auto errmsg = FormatMessageInternal();
		if (errmsg) {
			MessageWindowEx(
				m_hWnd,
				L"CreateProcess failed",
				errmsg,
				nullptr, kFatalWindow);
			LocalFree(errmsg);
		}
	}
	return S_OK;
}