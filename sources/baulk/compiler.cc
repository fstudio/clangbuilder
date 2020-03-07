#include <bela/env.hpp>
#include <bela/path.hpp>
#include "compiler.hpp"
#include "fs.hpp"
#include "jsonex.hpp"
#include "xml.hpp"

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
//

bool Executor::InitializeWindowsKitEnv(bela::error_code &ec) {
  std::wstring sdkroot =
      bela::ExpandEnv(L"%ProgramFiles(x86)%\\Windows Kits\\10");
  auto sdkmanifest = bela::StringCat(sdkroot, L"\\SDKManifest.xml");
  if (!bela::PathExists(sdkmanifest)) {
    std::wstring sdkroot = bela::ExpandEnv(L"%ProgramFiles%\\Windows Kits\\10");
    sdkmanifest = bela::StringCat(sdkroot, L"\\SDKManifest.xml");
    if (!bela::PathExists(sdkmanifest)) {
      ec = bela::make_error_code(1, L"Windows Kit not installed");
      return false;
    }
  }
  std::wstring sdkversion;
  if (!baulk::xml::ParseSdkVersion(sdkmanifest, sdkversion, ec)) {
    return false;
  }
  constexpr std::wstring_view incs[] = {L"\\um", L"\\ucrt", L"\\cppwinrt",
                                        L"\\shared", L"\\winrt"};
  for (auto i : incs) {
    TestJoin(bela::StringCat(sdkroot, L"\\Include\\", sdkversion, i), includes);
  }
  // libs
  TestJoin(bela::StringCat(sdkroot, L"\\Lib\\", sdkversion, L"\\um\\", arch),
           libs);
  TestJoin(bela::StringCat(sdkroot, L"\\Lib\\", sdkversion, L"\\ucrt\\", arch),
           libs);
  // Paths
  TestJoin(bela::StringCat(sdkroot, L"\\bin\\", arch), paths);
  TestJoin(bela::StringCat(sdkroot, L"\\bin\\", sdkversion, L"\\", arch),
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