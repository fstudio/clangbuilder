#include <bela/env.hpp>
#include <bela/path.hpp>
#include "compiler.hpp"
#include "fs.hpp"
#include "jsonex.hpp"
#include "regutils.hpp"

// C:\Program Files (x86)\Microsoft Visual
// Studio\2019\Community\VC\Auxiliary\Build
namespace baulk::compiler {

#ifdef _M_X64
// Always build x64 binary
[[maybe_unused]] constexpr std::wstring_view arch = L"x64"; // Hostx64 x64
#else
[[maybe_unused]] constexpr std::wstring_view arch = L"x86"; // Hostx86 x86
#endif

struct VisualStudioInstance {
  std::wstring installationPath;
  std::wstring installationVersion;
  std::wstring instanceId;
  std::wstring productId;
  bool isLaunchable{true};
  bool isPrerelease{false};
  bool Encode(const std::string_view result, bela::error_code &ec) {
    try {
      auto j0 = nlohmann::json::parse(result);
      if (!j0.is_array() || j0.empty()) {
        ec = bela::make_error_code(1, L"empty visual studio instance");
        return false;
      }
      auto &j = j0[0];
      baulk::json::BindTo(j, "installationPath", installationPath);
      baulk::json::BindTo(j, "installationVersion", installationVersion);
      baulk::json::BindTo(j, "instanceId", instanceId);
      baulk::json::BindTo(j, "productId", productId);
      baulk::json::BindTo(j, "isLaunchable", isLaunchable);
      baulk::json::BindTo(j, "isLaunchable", isLaunchable);
    } catch (const std::exception &e) {
      ec = bela::make_error_code(1, bela::ToWide(e.what()));
      return false;
    }
    return true;
  }
};

// const fs::path vswhere_exe = program_files_32_bit / "Microsoft Visual Studio"
// / "Installer" / "vswhere.exe";

std::optional<std::wstring> LookupVsWhere() {
  auto vswhere_exe =
      bela::StringCat(bela::GetEnv(L"ProgramFiles(x86)"),
                      L"/Microsoft Visual Studio/Installer/vswhere.exe");
  if (bela::PathExists(vswhere_exe)) {
    return std::make_optional(std::move(vswhere_exe));
  }
  vswhere_exe =
      bela::StringCat(bela::GetEnv(L"ProgramFiles"),
                      L"/Microsoft Visual Studio/Installer/vswhere.exe");
  if (bela::PathExists(vswhere_exe)) {
    return std::make_optional(std::move(vswhere_exe));
  }
  return std::nullopt;
}

std::optional<VisualStudioInstance>
LookupVisualStudioInstance(bela::error_code &ec) {
  auto vswhere_exe = LookupVsWhere();
  if (!vswhere_exe) {
    ec = bela::make_error_code(-1, L"vswhere not installed");
    return std::nullopt;
  }
  baulk::ProcessCapture process;
  if (process.Execute(*vswhere_exe, L"-format", L"json") != 0) {
    ec = process.ErrorCode();
    return std::nullopt;
  }
  return std::nullopt;
}
// HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Microsoft
// SDKs\Windows\v10.0 InstallationFolder ProductVersion

bool SDKSearchVersion(std::wstring_view sdkroot, std::wstring_view sdkver,
                      std::wstring &sdkversion) {
  auto dir = bela::StringCat(sdkroot, L"\\Include");
  for (auto &p : std::filesystem::directory_iterator(dir)) {
    auto filename = p.path().filename().wstring();
    if (bela::StartsWith(filename, sdkver)) {
      sdkversion = filename;
      return true;
    }
  }
  return true;
}

bool Executor::InitializeWindowsKitEnv(bela::error_code &ec) {
  auto winsdk = baulk::regutils::LookupWindowsSDK(ec);
  if (!winsdk) {
    return false;
  }
  std::wstring sdkversion;
  if (!SDKSearchVersion(winsdk->InstallationFolder, winsdk->ProductVersion,
                        sdkversion)) {
    ec = bela::make_error_code(1, L"invalid sdk version");
    return false;
  }
  constexpr std::wstring_view incs[] = {L"\\um", L"\\ucrt", L"\\cppwinrt",
                                        L"\\shared", L"\\winrt"};
  for (auto i : incs) {
    TestJoin(bela::StringCat(winsdk->InstallationFolder, L"\\Include\\",
                             sdkversion, i),
             includes);
  }
  // libs
  TestJoin(bela::StringCat(winsdk->InstallationFolder, L"\\Lib\\", sdkversion,
                           L"\\um\\", arch),
           libs);
  TestJoin(bela::StringCat(winsdk->InstallationFolder, L"\\Lib\\", sdkversion,
                           L"\\ucrt\\", arch),
           libs);
  // Paths
  TestJoin(bela::StringCat(winsdk->InstallationFolder, L"\\bin\\", arch),
           paths);
  TestJoin(bela::StringCat(winsdk->InstallationFolder, L"\\bin\\", sdkversion,
                           L"\\", arch),
           paths);
  return true;
}

// $installationPath/VC/Auxiliary/Build/Microsoft.VCToolsVersion.default.txt

bool Executor::Initialize(bela::error_code &ec) {
  auto vsi = LookupVisualStudioInstance(ec);
  if (!vsi) {
    // Visual Studio not install
    return false;
  }
  return false;
}
} // namespace baulk::compiler