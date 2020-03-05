///
#ifndef BAULK_PROCESS_HPP
#define BAULK_PROCESS_HPP
#include <bela/base.hpp>
#include <bela/phmap.hpp>
#include <bela/escapeargv.hpp>
#include <bela/env.hpp>
#include <bela/finaly.hpp>
#include <bela/stdwriter.hpp>

namespace baulk {
constexpr const wchar_t *string_nullable(std::wstring_view str) {
  return str.empty() ? nullptr : str.data();
}
constexpr wchar_t *string_nullable(std::wstring &str) {
  return str.empty() ? nullptr : str.data();
}
class Process {
public:
  Process() = default;
  Process(const Process &) = delete;
  Process &operator=(const Process &) = delete;
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
    return ExecuteInternal(ea.data());
  }
  const bela::error_code &ErrorCode() const { return ec; }

private:
  int ExecuteInternal(wchar_t *cmdline);
  DWORD pid{0};
  std::wstring workdir;
  bela::env::Derivator derivator;
  bela::error_code ec;
};
} // namespace baulk

#endif
