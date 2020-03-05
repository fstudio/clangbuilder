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
    process.SetEnv(L"Path", bela::env::InsertEnv(L"Path", paths));
    return 0;
  }

private:
  std::vector<std::wstring> paths;
  std::vector<std::wstring> libs;
  std::vector<std::wstring> includes;
  std::wstring cwd;
};
} // namespace baulk::compiler

#endif