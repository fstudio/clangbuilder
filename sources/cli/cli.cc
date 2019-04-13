/// clangbuiler lanucher script
#include "../cbui/inc/apphelp.hpp"
#include "../cbui/inc/argvbuilder.hpp"
#include "../cbui/inc/json.hpp"
#include "../cbui/inc/string.hpp"
#include "../cbui/inc/systemtools.hpp"
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

bool Executable(std::wstring &exe) {
  constexpr size_t pathcchmax = 0x8000;
  std::wstring engine_(pathcchmax, L'\0');
  auto buffer = &engine_[0];
  // std::array<wchar_t, PATHCCH_MAX_CCH> engine_;
  // If the function succeeds, the return value is the length of the string that
  // is copied to the buffer, in characters, not including the terminating null
  // character. If the buffer is too small to hold the module name, the string
  // is truncated to nSize characters including the terminating null character,
  // the function returns nSize, and the function sets the last error to
  // ERROR_INSUFFICIENT_BUFFER.
  auto N = GetModuleFileNameW(nullptr, buffer, pathcchmax);
  if (N <= 0) {
    return false;
  }
  exe.assign(buffer, N);
  return true;
}

// std::wstring_view LauncherAppName(std::wstring_view exe,
//                                   std::wstring_view *exepath) {
//   auto pos = exe.find_last_of(L"\\/");
//   if (pos == std::wstring_view::npos) {
//     return base::StripSuffix(exe, L".exe");
//   }
//   *exepath = exe.substr(0, pos);
//   exe.remove_prefix(pos + 1);
//   return base::StripSuffix(exe, L".exe");
// }

// rc /fo:cli.res ../cbui/res/cli.rc
// cl cli.cc -std:c++17 -O2 Pathcch.lib shell32.lib Shlwapi.lib cli.res
int wmain(int argc, wchar_t **argv) {
  // --> get some
  _wsetlocale(LC_ALL, L"");
  std::wstring exe;
  if (!Executable(exe)) {
    return 1;
  }
  auto ps1 = base::StringCat(base::StripSuffix(exe, L".exe"), L".ps1");
  if (!PathFileExistsW(ps1.data())) {
    wprintf_s(L"Powershell script '%s' not found\n", ps1.data());
    return 1;
  }
  auto pwshexe = PwshExePath();
  clangbuilder::argvbuilder ab;
  ab.assign(pwshexe)
      .append(L"-NoProfile")
      .append(L"-NoLogo")
      .append(L"-ExecutionPolicy")
      .append(L"unrestricted")
      .append(L"-File")
      .append(ps1);
  for (int i = 1; i < argc; i++) {
    ab.append(argv[i]);
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
  if (CreateProcessW(nullptr, ab.command(), NULL, NULL, FALSE,
                     NORMAL_PRIORITY_CLASS, NULL, NULL, &si, &pi) != TRUE) {
    auto ec = base::make_system_error_code();
    wprintf_s(L"CreateProcessW error: %s", ec.message.data());
    return 1;
  }
  CloseHandle(pi.hThread);
  WaitForSingleObject(pi.hProcess, INFINITE);
  DWORD exitCode;
  GetExitCodeProcess(pi.hProcess, &exitCode);
  CloseHandle(pi.hProcess);
  return exitCode;
}