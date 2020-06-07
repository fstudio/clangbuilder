///////////
#ifndef CLANGBUILDERUI_APP_HPP
#define CLANGBUILDERUI_APP_HPP
#include <vector>
#include <functional>
#include <vsinstance.hpp>
#include <bela/endian.hpp>

struct rgb {
  constexpr rgb() : r(0), g(0), b(0) {}
  constexpr rgb(uint8_t r_, uint8_t g_, uint8_t b_) : r(r_), g(g_), b(b_) {}
  constexpr rgb(uint32_t hex) : r((hex >> 16) & 0xFF), g((hex >> 8) & 0xFF), b(hex & 0xFF) {}
  constexpr rgb(COLORREF hex)
      : r((uint32_t(hex) >> 16) & 0xFF), g((uint32_t(hex) >> 8) & 0xFF), b(uint32_t(hex) & 0xFF) {}
  uint8_t r;
  uint8_t g;
  uint8_t b;
};

// swap to LE
inline COLORREF calcLuminance(UINT32 cr) {
  cr = bela::swaple(cr);
  int r = (cr & 0xff0000) >> 16;
  int g = (cr & 0xff00) >> 8;
  int b = (cr & 0xff);
  return RGB(r, g, b);
}

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
  bool SetWindowCompositionAttributeEnabled() const { return SetWindowCompositionAttribute_; }
  bool IsPwshCoreEnabled() const { return PwshCoreEnabled_; }
  bool UseWindowsTerminal() const { return UseWindowsTerminal_; }
  std::wstring PwshExePath();
  std::wstring_view EnterpriseWDK() const { return ewdkroot; }
  std::wstring_view Terminal() const { return terminal; }

private:
  bool InitializeWindowsTerminal();
  std::wstring ewdkroot;
  std::wstring terminal;
  bool SetWindowCompositionAttribute_{false};
  bool PwshCoreEnabled_{false};
  bool UseWindowsTerminal_{false};
};
bool SetWindowCompositionAttributeImpl(HWND hWnd);

#endif