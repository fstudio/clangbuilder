///
#ifndef BAULK_PROCESS_HPP
#define BAULK_PROCESS_HPP
#include <bela/base.hpp>
#include <bela/phmap.hpp>
#include <bela/escapeargv.hpp>
#include <bela/env.hpp>

namespace baulk {
class Process {
public:
  Process() {
    //
    SetConsoleCtrlHandler(nullptr, TRUE);
  }
  Process(const Process &) = delete;
  Process &operator=(const Process &) = delete;
  ~Process() {
    //
    SetConsoleCtrlHandler(nullptr, FALSE);
  }
  Process &Chdir(std::wstring_view dir) {
    workdir = dir;
    return *this;
  }
  Process &SetEnv(std::wstring_view key, std::wstring_view val,
                  bool force = false) {
    derivator.SetEnv(key, val, force);
    return *this;
  }
  template <typename... Args> int Execute(std::wstring_view cmd, Args... args) {
    bela::EscapeArgv ea(cmd, args...);
    return 0;
  }

private:
  DWORD pid{0};
  std::wstring workdir;
  bela::env::Derivator derivator;
};
} // namespace baulk

#endif
