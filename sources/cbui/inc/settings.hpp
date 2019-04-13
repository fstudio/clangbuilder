////////////
#ifndef CLANGBUILDERUI_SETTINGS_HPP
#define CLANGBUILDERUI_SETTINGS_HPP
#include "base.hpp"

class Settings {
public:
  Settings() = default;
  Settings(const Settings &) = delete;
  Settings &operator=(const Settings &) = delete;
  bool Initialize(std::wstring_view root);
  bool SetWindowCompositionAttributeEnabled() const {
    return SetWindowCompositionAttribute_;
  }
  bool IsPwshCoreEnabled() const { return PwshCoreEnabled_; }
  std::wstring PwshExePath();

private:
  bool SetWindowCompositionAttribute_{false};
  bool PwshCoreEnabled_{false};
};
bool SetWindowCompositionAttributeImpl(HWND hWnd);
#endif