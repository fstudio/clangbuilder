/// clangbuiler lanucher script
#include "../include/appfs.hpp"
#include "../include/argvbuilder.hpp"
#include "../include/json.hpp"
#include "../include/string.hpp"
#include "../include/systemtools.hpp"
#include <cstdio>

bool IsPwshEnabled() {
  std::wstring target, root;
  base::error_code ec;
  if (!clangbuilder::LookupClangbuilderTarget(root, target, ec)) {
    return false;
  }
  auto file = base::StringCat(root, L"\\config\\settings.json");
  clangbuilder::FD fd;
  if (_wfopen_s(&fd.fd, file.data(), L"rb") != 0) {
    return false;
  }
  try {
    auto j = nlohmann::json::parse(fd.P());
    return j["PwshCoreEnabled"].get<bool>();
  } catch (const std::exception &) {
    // fprintf(stderr, "debug %s\n", e.what());
    return false;
  }
  return false;
}

std::wstring PwshExePath() {
  std::wstring pwshexe;
  if (IsPwshEnabled() && clangbuilder::LookupPwshCore(pwshexe)) {
    return pwshexe;
  }
  if (clangbuilder::LookupPwshDesktop(pwshexe)) {
    return pwshexe;
  }
  return L"";
}

std::wstring LauncherTarget(std::wstring_view Arg0) {
  // --> Arg0 to fullpath, replace ".exe" to ".ps1"
  std::wstring absArg0;
  if (!clangbuilder::PathAbsolute(absArg0, Arg0)) {
    return L"";
  }
  return base::StringCat(base::StripSuffix(absArg0, L".exe"), L".ps1");
}

// rc /fo:cli.res ../cbui/res/cli.rc
// cl cli.cc -std:c++17 -O2 Pathcch.lib shell32.lib Shlwapi.lib cli.res
int wmain(int argc, wchar_t **argv) {
  // --> launcher some ps1 file
  _wsetlocale(LC_ALL, L"");
  auto ps1 = LauncherTarget(argv[0]);
  if (!clangbuilder::PathExists(ps1)) {
    wprintf_s(L"Powershell script '%s' not found\n", ps1.data());
    return 1;
  }
  auto pwshexe = PwshExePath();
  clangbuilder::ArgvBuilder ab;
  ab.Assign(pwshexe)
      .Append(L"-NoProfile")
      .Append(L"-NoLogo")
      .Append(L"-ExecutionPolicy")
      .Append(L"unrestricted")
      .Append(L"-File")
      .Append(ps1);
  for (int i = 1; i < argc; i++) {
    ab.Append(argv[i]);
  }

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
  if (CreateProcessW(nullptr, ab.Command(), NULL, NULL, FALSE,
                     CREATE_UNICODE_ENVIRONMENT, NULL, NULL, &si,
                     &pi) != TRUE) {
    auto ec = base::make_system_error_code();
    wprintf_s(L"CreateProcessW error: %s", ec.message.data());
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
