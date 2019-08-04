///////////
#ifndef CLANGBUILDERUI_APP_HPP
#define CLANGBUILDERUI_APP_HPP
#include <vector>
#include <functional>
#include <vsinstance.hpp>

class VisualStudioSeacher {
public:
  using container_t = std::vector<clangbuilder::VSInstance>;
  VisualStudioSeacher() = default;
  VisualStudioSeacher(const VisualStudioSeacher &) = delete;
  VisualStudioSeacher &operator=(const VisualStudioSeacher &) = delete;
  bool Execute(std::wstring_view root, std::wstring_view ewdkroot);
  const container_t &Instances() const { return instances; }
  int Index() const {
    if (instances.empty()) {
      return 0;
    }
    return static_cast<int>(instances.size() - 1);
  }
  size_t Size() const { return instances.size(); }
  const wchar_t *Version(int i) const {
    if (i < 0 || i >= instances.size()) {
      return L"";
    }
    return instances[i].Version.data();
  }

  std::wstring_view InstallVersion(int i) const {
    if (i < 0 || i >= instances.size()) {
      return L"0";
    }
    return instances[i].Version;
  }
  std::wstring_view InstanceId(int i) const {
    if (i < 0 || i >= instances.size()) {
      return L"-";
    }
    return instances[i].InstanceId;
  }

private:
  container_t instances;
  bool EnterpriseWDK(std::wstring_view ewdkroot, clangbuilder::VSInstance &vsi);
};

class Settings {
public:
  using invoke_t = std::function<void(const std::wstring &)>;
  Settings() = default;
  Settings(const Settings &) = delete;
  Settings &operator=(const Settings &) = delete;
  bool Initialize(std::wstring_view root, const invoke_t &call);
  bool SetWindowCompositionAttributeEnabled() const {
    return SetWindowCompositionAttribute_;
  }
  bool IsPwshCoreEnabled() const { return PwshCoreEnabled_; }
  std::wstring PwshExePath();
  std::wstring_view EnterpriseWDK() const { return ewdkroot; }
  std::wstring_view Conhost() const { return conhost; }

private:
  std::wstring ewdkroot;
  std::wstring conhost;
  bool SetWindowCompositionAttribute_{false};
  bool PwshCoreEnabled_{false};
};
bool SetWindowCompositionAttributeImpl(HWND hWnd);

#endif