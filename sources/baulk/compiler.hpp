//
#ifndef BAULK_COMPILER_HPP
#define BAULK_COMPILER_HPP
#include "process.hpp"

namespace baulk::compiler {
class Executor {
public:
  using vector_t = std::vector<std::wstring>;
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
  bool InitializeWindowsKitEnv(bela::error_code &ec);
  bool TestJoin(std::wstring &&p, vector_t &vec) {
    if (bela::PathExists(p)) {
      vec.emplace_back(std::move(p));
      return true;
    }
    return false;
  }
};
} // namespace baulk::compiler

#endif