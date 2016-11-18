//////////////
#include "stdafx.h"
#include "Clangbuilder.h"

static VisualStudioToolsEnv vsenv[] = {
	{ L"11.0", L"Visual Studio 2012 for Windows 8", 110 },
	{ L"12.0", L"Visual Studio 2013 for Windows 8.1", 120 },
	{ L"14.0", L"Visual Studio 2015 for Windows 8.1", 140 },
	{ L"14.0", L"Visual Studio 2015 for Windows 10", 141 },
	{ L"15.0", L"Visual Studio 2017 for Windows10", 150 }
};

/// HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\SxS\VS7 11.0 12.0 14.0 15.0

#if defined(_M_X64)
#define VSREG_KEY L"SOFTWARE\\WOW6432Node\\Microsoft\\VisualStudio\\SxS\\VS7"
#else
#define VSREG_KEY L"SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7"
#endif


bool VisualStudioExists(const wchar_t *key)
{
	HKEY hInst = nullptr;
	if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, VSREG_KEY, 0, KEY_READ, &hInst) != ERROR_SUCCESS) {
		/// Not Found Key
		return false;
	}
	DWORD type = REG_SZ;
	WCHAR buffer[4096];
	DWORD dwSize = sizeof(buffer);
	if (RegGetValueW(hInst, nullptr, key, RRF_RT_REG_SZ, &type,
		buffer, &dwSize) != ERROR_SUCCESS) {
		RegCloseKey(hInst);
		return false;
	}
	RegCloseKey(hInst);
	return true;
}

bool VisualStudioSearch(std::vector<VisualStudioIndex> &index)
{
	index.clear();
	for (auto &v : vsenv) {
		if (VisualStudioExists(v.env)) {
			index.push_back(VisualStudioIndex(v));
		}
	}
	return true;
}