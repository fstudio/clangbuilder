/////
#include <json.hpp>
#include <systemtools.hpp>
#include <appfs.hpp>
#include "app.hpp"
/////
struct ACCENTPOLICY {
  int nAccentState;
  int nFlags;
  int nColor;
  int nAnimationId;
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
    ACCENTPOLICY policy = {ACCENT_ENABLE_BLURBEHIND, 0, 0, 0};
    WINCOMPATTRDATA data = {19, &policy, sizeof(ACCENTPOLICY)};
    result = SetWindowCompositionAttribute(hWnd, &data);
  }
  FreeLibrary(hModule);
  return result;
}

bool Settings::Initialize(std::wstring_view root, const invoke_t &call) {
  auto file = base::StringCat(root, L"\\config\\settings.json");
  clangbuilder::FD fd;
  if (_wfopen_s(&fd.fd, file.data(), L"rb") != 0) {
    return false;
  }
  try {
    auto j = nlohmann::json::parse(fd.P());
    auto it = j.find("PwshCoreEnabled");
    if (it != j.end()) {
      PwshCoreEnabled_ = it.value().get<bool>();
    }
    it = j.find("EnterpriseWDK");
    if (it != j.end()) {
      ewdkroot = base::ToWide(it.value().get<std::string>());
    }
    it = j.find("SetWindowCompositionAttribute");
    if (it != j.end()) {
      SetWindowCompositionAttribute_ = it.value().get<bool>();
    }

  } catch (const std::exception &e) {
    call(base::ToWide(e.what()));
    return false;
  }
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