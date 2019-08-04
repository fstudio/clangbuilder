///////
/// clangbuiler lanucher script
#include <appfs.hpp>
#include <systemtools.hpp>
#include <bela/escapeargv.hpp>
#include <bela/stdwriter.hpp>
#include <bela/strip.hpp>
#include <cstdio>

#ifndef ENABLE_VIRTUAL_TERMINAL_PROCESSING
#define ENABLE_VIRTUAL_TERMINAL_PROCESSING 0x0004
#endif

inline bool enable_vt_mode(HANDLE hFile) {
  DWORD dwMode = 0;
  if (!GetConsoleMode(hFile, &dwMode)) {
    return false;
  }
  dwMode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
  if (!SetConsoleMode(hFile, dwMode)) {
    return false;
  }
  return true;
}

bool enable_vt_console() {
  auto hStderr = GetStdHandle(STD_OUTPUT_HANDLE);
  auto hStdout = GetStdHandle(STD_ERROR_HANDLE);
  return enable_vt_mode(hStderr) && enable_vt_mode(hStdout);
}

int ExecuteWait(wchar_t *command) {
  PROCESS_INFORMATION pi;
  STARTUPINFOW si;
  ZeroMemory(&si, sizeof(si));
  ZeroMemory(&pi, sizeof(pi));
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESHOWWINDOW;
  si.wShowWindow = SW_SHOW;
#if defined(_M_IX86) || defined(_M_ARM)
  //// Only x86,ARM on Windows 64
  clangbuilder::FsRedirection fsRedirection;
#endif
  if (CreateProcessW(nullptr, command, NULL, NULL, FALSE,
                     CREATE_UNICODE_ENVIRONMENT, NULL, NULL, &si,
                     &pi) != TRUE) {
    auto ec = bela::make_system_error_code();
    bela::FPrintF(stderr, L"CreateProcessW error: %s", ec.message);
    return 1;
  }
  CloseHandle(pi.hThread);
  SetConsoleCtrlHandler(nullptr, TRUE);
  WaitForSingleObject(pi.hProcess, INFINITE);
  SetConsoleCtrlHandler(nullptr, FALSE);
  DWORD exitCode;
  GetExitCodeProcess(pi.hProcess, &exitCode);
  CloseHandle(pi.hProcess);
  return exitCode;
}

std::wstring LauncherTarget(std::wstring_view Arg0) {
  // --> Arg0 to fullpath, replace ".exe" to ".bat"
  std::wstring absArg0;
  if (!clangbuilder::PathAbsolute(absArg0, Arg0)) {
    return L"";
  }
  return bela::StringCat(bela::StripSuffix(absArg0, L".exe"), L".bat");
}

std::wstring SystemCMD() {
  auto cmd = bela::GetEnv(L"ComSpec");
  if (!cmd.empty()) {
    SetConsoleTitleW(cmd.data());
    return cmd;
  }
  return L"cmd.exe";
}

int simplifycmd(int argc, wchar_t **argv) {
  bela::EscapeArgv ea;
  ea.Assign(SystemCMD());
  for (int i = 1; i < argc; i++) {
    ea.Append(argv[i]);
  }
  return ExecuteWait(ea.data());
}

int wmain(int argc, wchar_t **argv) {
  enable_vt_console(); // to enable VT console
  if (bela::EndsWithIgnoreCase(argv[0], L"cmdex.exe")) {
    return simplifycmd(argc--, argv++);
  }
  auto batfile = LauncherTarget(argv[0]);
  if (!clangbuilder::PathExists(batfile)) {
    bela::FPrintF(stderr, L"Batch file: %s not exists\n", batfile);
    return 1;
  }
  bela::EscapeArgv ea;
  ea.Assign(SystemCMD()).Append(L"/k").Append(batfile);
  for (int i = 1; i < argc; i++) {
    ea.Append(argv[i]);
  }
  return ExecuteWait(ea.data());
}
