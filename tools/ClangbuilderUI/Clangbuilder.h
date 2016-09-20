///

#ifndef CLANGBUILDER_H
#define CLANGBUILDER_H
#include <vector>
#include <string>

struct VisualStudioToolsEnv {
	const wchar_t *env;
	const wchar_t *name;
	int version;
};

struct VisualStudioIndex {
	VisualStudioIndex(VisualStudioToolsEnv &e)
	{
		index = -1;
		version = e.version;
		name.assign(e.name);
	}
	int index;
	int version;
	std::wstring name;
};




bool VisualStudioSearch(std::vector<VisualStudioIndex> &index);
#endif