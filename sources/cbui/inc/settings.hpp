////////////
#ifndef CLANGBUILDERUI_SETTINGS_HPP
#define CLANGBUILDERUI_SETTINGS_HPP
#include "base.hpp"
#include <functional>

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

private:
  std::wstring ewdkroot;
  bool SetWindowCompositionAttribute_{false};
  bool PwshCoreEnabled_{false};
};
bool SetWindowCompositionAttributeImpl(HWND hWnd);
#endif