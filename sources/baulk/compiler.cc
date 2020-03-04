#include "compiler.hpp"
#include "fs.hpp"
#include <bela/env.hpp>
#include <bela/path.hpp>
// C:\Program Files (x86)\Microsoft Visual
// Studio\2019\Community\VC\Auxiliary\Build
namespace baulk::compiler {
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

struct VsInstance {
  std::wstring install;
  std::wstring vcversion;
};

bool Executor::Initialize(bela::error_code &ec) {
  //
  return false;
}
} // namespace baulk::compiler