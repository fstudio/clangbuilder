/////
#include <json.hpp>
#include <systemtools.hpp>
#include <appfs.hpp>
#include <bela/env.hpp>
#include <bela/path.hpp>
#include "app.hpp"
/////
struct WINCOMPATTRDATA {
  DWORD attribute;
  PVOID pData;
  ULONG dataSize;
};

typedef enum _WINDOWCOMPOSITIONATTRIB {
  WCA_UNDEFINED = 0,
  WCA_NCRENDERING_ENABLED = 1,
  WCA_NCRENDERING_POLICY = 2,
  WCA_TRANSITIONS_FORCEDISABLED = 3,
  WCA_ALLOW_NCPAINT = 4,
  WCA_CAPTION_BUTTON_BOUNDS = 5,
  WCA_NONCLIENT_RTL_LAYOUT = 6,
  WCA_FORCE_ICONIC_REPRESENTATION = 7,
  WCA_EXTENDED_FRAME_BOUNDS = 8,
  WCA_HAS_ICONIC_BITMAP = 9,
  WCA_THEME_ATTRIBUTES = 10,
  WCA_NCRENDERING_EXILED = 11,
  WCA_NCADORNMENTINFO = 12,
  WCA_EXCLUDED_FROM_LIVEPREVIEW = 13,
  WCA_VIDEO_OVERLAY_ACTIVE = 14,
  WCA_FORCE_ACTIVEWINDOW_APPEARANCE = 15,
  WCA_DISALLOW_PEEK = 16,
  WCA_CLOAK = 17,
  WCA_CLOAKED = 18,
  WCA_ACCENT_POLICY = 19,
  WCA_FREEZE_REPRESENTATION = 20,
  WCA_EVER_UNCLOAKED = 21,
  WCA_VISUAL_OWNER = 22,
  WCA_LAST = 23
} WINDOWCOMPOSITIONATTRIB;

typedef struct WINDOWCOMPOSITIONATTRIBDATA {
  WINDOWCOMPOSITIONATTRIB Attrib;
  PVOID pvData;
  SIZE_T cbData;
} WINDOWCOMPOSITIONATTRIBDATA;

typedef enum _ACCENT_STATE {
  ACCENT_DISABLED = 0,                   // Black and solid background
  ACCENT_ENABLE_GRADIENT = 1,            // Custom-colored solid background
  ACCENT_ENABLE_TRANSPARENTGRADIENT = 2, // Custom-colored transparent background
  ACCENT_ENABLE_BLURBEHIND = 3,          // Custom-colored and blurred transparent background
  ACCENT_ENABLE_FLUENT = 4,              // Custom-colored Fluent effect
  ACCENT_INVALID_STATE = 5               // Completely transparent background
} ACCENT_STATE;

typedef struct _ACCENT_POLICY {
  ACCENT_STATE nAccentState; // Appearance
  int32_t nFlags;            // Nobody knows how this value works
  uint32_t nColor;           // A color in the hex format AABBGGRR
  int32_t nAnimationId;      // Nobody knows how this value works
} ACCENT_POLICY;

bool SetWindowCompositionAttributeImpl(HWND hWnd) {
  typedef BOOL(WINAPI * pSetWindowCompositionAttribute)(HWND, WINDOWCOMPOSITIONATTRIBDATA *);
  bool result = false;
  const HINSTANCE hModule = LoadLibrary(TEXT("user32.dll")); // LoadLibrary need free
  const pSetWindowCompositionAttribute SetWindowCompositionAttribute =
      (pSetWindowCompositionAttribute)GetProcAddress(hModule, "SetWindowCompositionAttribute");

  // Only works on Win10
  if (SetWindowCompositionAttribute) {
    ACCENT_POLICY policy = {ACCENT_ENABLE_FLUENT, 2, 0, 0};
    policy.nColor = (0x01 << 24) + (calcLuminance(0x808080) & 0x00FFFFFF);
    WINDOWCOMPOSITIONATTRIBDATA data;
    data.Attrib = WCA_ACCENT_POLICY;
    data.pvData = &policy;
    data.cbData = sizeof(policy);
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
    auto j = nlohmann::json::parse(fd.P(), nullptr, true, true);

    if (auto it = j.find("PwshCoreEnabled"); it != j.end()) {
      PwshCoreEnabled_ = it.value().get<bool>();
    }
    if (auto it = j.find("EnterpriseWDK"); it != j.end()) {
      ewdkroot = bela::ToWide(it.value().get<std::string>());
    }

    if (auto it = j.find("SetWindowCompositionAttribute"); it != j.end()) {
      SetWindowCompositionAttribute_ = it.value().get<bool>();
    }
    if (auto it = j.find("UseWindowsTerminal"); it != j.end() && it.value().get<bool>()) {
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
  UseWindowsTerminal_ = true;
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