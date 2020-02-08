/////
#include <json.hpp>
#include <systemtools.hpp>
#include <appfs.hpp>
#include <bela/env.hpp>
#include <bela/path.hpp>
#include "app.hpp"
/////
struct ACCENTPOLICY {
  uint32_t nAccentState;
  uint32_t nFlags;
  uint32_t nColor;
  uint32_t nAnimationId;
};
struct WINCOMPATTRDATA {
  int nAttribute;
  PVOID pData;
  ULONG ulDataSize;
};

enum AccentTypes {
  ACCENT_DISABLED = 0,        // Black and solid background
  ACCENT_ENABLE_GRADIENT = 1, // Custom-colored solid background
  ACCENT_ENABLE_TRANSPARENTGRADIENT =
      2, // Custom-colored transparent background
  ACCENT_ENABLE_BLURBEHIND =
      3,                    // Custom-colored and blurred transparent background
  ACCENT_ENABLE_FLUENT = 4, // Custom-colored Fluent effect
  ACCENT_INVALID_STATE = 5  // Completely transparent background
};

bool SetWindowCompositionAttributeImpl(HWND hWnd) {
  typedef BOOL(WINAPI * pSetWindowCompositionAttribute)(HWND,
                                                        WINCOMPATTRDATA *);
  bool result = false;
  const HINSTANCE hModule =
      LoadLibrary(TEXT("user32.dll")); // LoadLibrary need free
  const pSetWindowCompositionAttribute SetWindowCompositionAttribute =
      (pSetWindowCompositionAttribute)GetProcAddress(
          hModule, "SetWindowCompositionAttribute");

  // Only works on Win10
  if (SetWindowCompositionAttribute) {
    ACCENTPOLICY policy = {ACCENT_ENABLE_BLURBEHIND, 2, 0xaa000000, 0};
    WINCOMPATTRDATA data = {19, &policy, sizeof(ACCENTPOLICY)};
    result = SetWindowCompositionAttribute(hWnd, &data);
  }
  FreeLibrary(hModule);
  return result;
}

bool Settings::Initialize(std::wstring_view root, const invoke_t &call) {
  auto file = bela::StringCat(root, L"\\config\\settings.json");
  clangbuilder::FD fd;
  if (_wfopen_s(&fd.fd, file.data(), L"rb") != 0) {
    return false;
  }
  try {
    auto j = nlohmann::json::parse(fd.P());

    if (auto it = j.find("PwshCoreEnabled"); it != j.end()) {
      PwshCoreEnabled_ = it.value().get<bool>();
    }
    if (auto it = j.find("EnterpriseWDK"); it != j.end()) {
      ewdkroot = bela::ToWide(it.value().get<std::string>());
    }

    if (auto it = j.find("SetWindowCompositionAttribute"); it != j.end()) {
      SetWindowCompositionAttribute_ = it.value().get<bool>();
    }
    if (auto it = j.find("UseWindowsTerminal");
        it != j.end() && it.value().get<bool>()) {
      if (InitializeWindowsTerminal()) {
        return true;
      }
    }
    if (auto it = j.find("Conhost"); it != j.end()) {
      auto conhost = bela::ToWide(it.value().get<std::string>());
      if (bela::PathExists(conhost)) {
        terminal.assign(std::move(conhost));
      }
    }

  } catch (const std::exception &e) {
    call(bela::ToWide(e.what()));
    return false;
  }
  return true;
}

// %LOCALAPPDATA%/Microsoft/WindowsApps
bool Settings::InitializeWindowsTerminal() {
  auto wt = bela::ExpandEnv(L"%LOCALAPPDATA%\\Microsoft\\WindowsApps\\wt.exe");
  if (!bela::PathExists(wt)) {
    return false;
  }
  terminal.assign(std::move(wt));
  return true;
}

std::wstring Settings::PwshExePath() {
  std::wstring pwshexe;
  if (PwshCoreEnabled_ && clangbuilder::LookupPwshCore(pwshexe)) {
    return pwshexe;
  }
  if (clangbuilder::LookupPwshDesktop(pwshexe)) {
    return pwshexe;
  }
  return L"";
}