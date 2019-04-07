////////
#ifndef CBUI_VSSEARCH_HPP
#define CBUI_VSSEARCH_HPP
#include <string>
#include <string_view>

struct VisualStudioInsatnce {
  std::wstring InstanceId;
  std::wstring InstallVersion;
  std::wstring Description;
  bool Prereleased{false};
};

class VisualStudioSeacher {
public:
  VisualStudioSeacher() = default;
  VisualStudioSeacher(const VisualStudioSeacher &) = delete;
  VisualStudioSeacher &operator=(const VisualStudioSeacher &) = delete;
  bool Execute();

private:
};

#endif