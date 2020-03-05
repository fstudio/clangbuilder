//
#include "process.hpp"

namespace baulk {
int Process::ExecuteInternal(wchar_t *cmdline) {
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