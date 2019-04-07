///

#ifndef CLANGBUILDER_H
#define CLANGBUILDER_H
#include <vector>
#include <string>

// enum KnownVisualStudio {
//	kVisualStudio2013 = 2013,
//	kVisualStudio2015 = 2015,
//	kVisualStudio2017 = 2017
//};
// flexible

struct VisualStudioInstance {
  VisualStudioInstance() = default;
  VisualStudioInstance(const std::wstring &des, const std::wstring &ver,
                       const std::wstring &id)
      : description(des), installversion(ver), instanceId(id) {}
  std::wstring description;
  std::wstring installversion;
  std::wstring instanceId;
};

bool VisualStudioSearch(const std::wstring &cbroot,
                        std::vector<VisualStudioInstance> &instances);
#endif