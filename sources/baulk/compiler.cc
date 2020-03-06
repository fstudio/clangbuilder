#include <bela/env.hpp>
#include <bela/path.hpp>
#include "compiler.hpp"
#include "fs.hpp"
#include <json.hpp>

// C:\Program Files (x86)\Microsoft Visual
// Studio\2019\Community\VC\Auxiliary\Build
namespace baulk::compiler {
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
      if (auto it = j.find("installationPath"); it != j.end()) {
        installationPath = bela::ToWide(it->get_ref<const std::string &>());
      }
      if (auto it = j.find("installationVersion"); it != j.end()) {
        installationVersion = bela::ToWide(it->get_ref<const std::string &>());
      }
      if (auto it = j.find("instanceId"); it != j.end()) {
        instanceId = bela::ToWide(it->get_ref<const std::string &>());
      }
      if (auto it = j.find("productId"); it != j.end()) {
        productId = bela::ToWide(it->get_ref<const std::string &>());
      }
      if (auto it = j.find("isLaunchable"); it != j.end()) {
        isLaunchable = it->get<bool>();
      }
      if (auto it = j.find("isPrerelease"); it != j.end()) {
        isPrerelease = it->get<bool>();
      }
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

bool Executor::Initialize(bela::error_code &ec) {
  //
  return false;
}
} // namespace baulk::compiler