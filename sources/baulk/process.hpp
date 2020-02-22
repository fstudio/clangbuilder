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

inline int Process::ExecuteInternal(wchar_t *cmdline) {
  // run a new process and wait
  STARTUPINFOW si;
  PROCESS_INFORMATION pi;
  SecureZeroMemory(&si, sizeof(si));
  SecureZeroMemory(&pi, sizeof(pi));
  si.cb = sizeof(si);
  auto env = derivator.Encode();
  bela::FPrintF(stderr, L"baulk$ %s\n", cmdline);
  if (CreateProcessW(nullptr, cmdline, nullptr, nullptr, FALSE,
                     CREATE_UNICODE_ENVIRONMENT,
                     reinterpret_cast<LPVOID>(string_nullable(env)),
                     string_nullable(workdir), &si, &pi) != TRUE) {
    ec = bela::make_system_error_code();
    return -1;
  }
  SetConsoleCtrlHandler(nullptr, TRUE);
  auto closer = bela::finally([&] {
    //
    SetConsoleCtrlHandler(nullptr, FALSE);
    CloseHandle(pi.hProcess);
  });
  WaitForSingleObject(pi.hProcess, INFINITE);
  DWORD exitCode;
  GetExitCodeProcess(pi.hProcess, &exitCode);
  return exitCode;
}
} // namespace baulk

#endif
