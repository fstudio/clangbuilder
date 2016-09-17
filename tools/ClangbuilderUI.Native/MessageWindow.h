////
#ifndef MESSAGEWINDOW_H
#define MESSAGEWINDOW_H

enum MessageWinodwEnum {
	kInfoWindow,
	kWarnWindow,
	kFatalWindow,
	kAboutWindow
};

HRESULT WINAPI MessageWindowEx(
	HWND hWnd,
	LPCWSTR pszWindowTitle,
	LPCWSTR pszContent,
	LPCWSTR pszExpandedInfo,
	MessageWinodwEnum type);

#endif