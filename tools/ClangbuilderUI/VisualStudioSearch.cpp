//////////////
#include "stdafx.h"
#include "Clangbuilder.h"

static VisualStudioToolsEnv vsenv[] = {
	{ L"VS110COMNTOOLS", L"Visual Studio 2012 for Windows 8",110 },
	{ L"VS120COMNTOOLS", L"Visual Studio 2013 for Windows 8.1",120 },
	{ L"VS140COMNTOOLS", L"Visual Studio 2015 for Windows 8.1",140 },
	{ L"VS140COMNTOOLS", L"Visual Studio 2015 for Windows 10",141 },
	{ L"VS150COMNTOOLS", L"Visual Studio 15 for Windows10", 150 }
};

bool EnvExists(const wchar_t *e_)
{
	return (GetEnvironmentVariableW(e_, nullptr, 0)>0);
}

bool VisualStudioSearch(std::vector<VisualStudioIndex> &index)
{
	index.clear();
	for (auto &v : vsenv) {
		if (EnvExists(v.env)) {
			index.push_back(VisualStudioIndex(v));
		}
	}
	return true;
}