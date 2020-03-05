//
#ifndef BAULK_COMPILER_HPP
#define BAULK_COMPILER_HPP
#include "process.hpp"

namespace baulk::compiler {
class Executor {
public:
  Executor() = default;
  Executor(const Executor &) = delete;
  Executor &operator=(const Executor &) = delete;
  bool Initialize(bela::error_code &ec);
  void Chdir(std::wstring_view dir) { cwd = dir; }
  template <typename... Args> int Execute(std::wstring_view cmd, Args... args) {
    baulk::Process process;
    process.SetEnv(L"LIB", bela::env::JoinEnv(libs));
    process.SetEnv(L"INCLUDE", bela::env::JoinEnv(includes));
    process.SetEnv(L"LIBPATH", bela::env::JoinEnv(libpaths));
    process.SetEnv(L"Path", bela::env::InsertEnv(L"Path", paths));
    process.Chdir(cwd);
    if (auto exitcode = process.Execute(cmd, std::forward<Args>(args)...);
        exitcode != 0) {
      ec = process.ErrorCode();
      return exitcode;
    }
    return 0;
  }

private:
  std::vector<std::wstring> paths;
  std::vector<std::wstring> libs;
  std::vector<std::wstring> includes;
  std::vector<std::wstring> libpaths;
  std::wstring cwd;
  bela::error_code ec;
};
} // namespace baulk::compiler

#endif