///  Powershell Loader, select Powershell 6 or 5
#include <Shlwapi.h>
#include <Windows.h>
#include <string>

#ifndef _M_X64
typedef BOOL(WINAPI *LPFN_ISWOW64PROCESS)(HANDLE, PBOOL);
typedef BOOL(WINAPI *LPFN_ISWOW64PROCESS2)(HANDLE, PUSHORT, PUSHORT);

HMODULE KrModule() {
  static HMODULE hModule = GetModuleHandleW(L"kernel32.dll");
  if (hModule == nullptr) {
    OutputDebugStringW(L"GetModuleHandleW failed");
  }
  return hModule;
}

class FsRedirection {
public:
  typedef BOOL WINAPI fntype_Wow64DisableWow64FsRedirection(PVOID *OldValue);
  typedef BOOL WINAPI fntype_Wow64RevertWow64FsRedirection(PVOID *OldValue);
  FsRedirection() {
    auto hModule = KrModule();
    auto pfnWow64DisableWow64FsRedirection =
        (fntype_Wow64DisableWow64FsRedirection *)GetProcAddress(
            hModule, "Wow64DisableWow64FsRedirection");
    if (pfnWow64DisableWow64FsRedirection) {
      pfnWow64DisableWow64FsRedirection(&OldValue);
    }
  }
  ~FsRedirection() {
    auto hModule = KrModule();
    auto pfnWow64RevertWow64FsRedirection =
        (fntype_Wow64RevertWow64FsRedirection *)GetProcAddress(
            hModule, "Wow64RevertWow64FsRedirection");
    if (pfnWow64RevertWow64FsRedirection) {
      pfnWow64RevertWow64FsRedirection(&OldValue);
    }
  }

private:
  PVOID OldValue = NULL;
};
#endif

class Arguments {
public:
  Arguments() : argv_(4096, L'\0') {}
  Arguments &assign(const wchar_t *app) {
    auto end = app + wcslen(app);
    std::wstring buf;
    bool needwarp = false;
    for (auto iter = app; iter != end; iter++) {
      switch (*iter) {
      case L'"':
        buf.push_back(L'\\');
        buf.push_back(L'"');
        break;
      case L'\t':
        needwarp = true;
        break;
      case L' ':
        needwarp = true;
      default:
        buf.push_back(*iter);
        break;
      }
    }
    if (needwarp) {
      argv_.assign(L"\"").append(buf).push_back(L'"');
    } else {
      argv_.assign(std::move(buf));
    }
    return *this;
  }
  Arguments &append(const wchar_t *cmd) {
    std::wstring buf;
    bool needwarp = false;
    auto end = cmd + wcslen(cmd);
    for (auto iter = cmd; iter != end; iter++) {
      switch (*iter) {
      case L'"':
        buf.push_back(L'\\');
        buf.push_back(L'"');
        break;
      case L' ':
      case L'\t':
        needwarp = true;
      default:
        buf.push_back(*iter);
        break;
      }
    }
    if (needwarp) {
      argv_.append(L" \"").append(buf).push_back(L'"');
    } else {
      argv_.append(L" ").append(buf);
    }
    return *this;
  }
  const std::wstring &str() { return argv_; }

private:
  std::wstring argv_;
};

std::wstring ExpandEnvironmentStringsWapper(const wchar_t *str) {
  std::wstring rstr(0x8000, L'\0');
  auto N = ExpandEnvironmentStringsW(str, &rstr[0], 0x8000);
  if (N >= 0) {
    rstr.resize(N - 1);
  } else {
    rstr.clear();
  }
  return rstr;
}

// powershell.exe
bool PowershellCore(std::wstring &pscore) {
  bool success = false;
  auto psdir = ExpandEnvironmentStringsWapper(L"%ProgramFiles%\\Powershell");
  if (!PathFileExistsW(psdir.c_str())) {
    psdir = ExpandEnvironmentStringsWapper(L"%ProgramW6432%\\Powershell");
    if (!PathFileExistsW(psdir.c_str())) {
      return false;
    }
  }
  WIN32_FIND_DATAW wfd;
  auto findstr = psdir + L"\\*";
  HANDLE hFind = FindFirstFileW(findstr.c_str(), &wfd);
  if (hFind == INVALID_HANDLE_VALUE) {
    return false; /// Not found
  }
  do {
    if (wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
      pscore.assign(psdir)
          .append(L"\\")
          .append(wfd.cFileName)
          .append(L"\\pwsh.exe");
      if (PathFileExistsW(pscore.c_str())) {
        success = true;
        break;
      }
    }
  } while (FindNextFileW(hFind, &wfd));
  FindClose(hFind);
  return success;
}

bool PowershellDesktop(std::wstring &psdesktop) {
  psdesktop = ExpandEnvironmentStringsWapper(
      L"%SystemRoot%/System32/WindowsPowerShell/v1.0/powershell.exe");
  if (!PathFileExistsW(psdesktop.c_str())) {
    return false;
  }
  return true;
}

bool PowershellSelect(std::wstring &psfile, bool selectcore = false) {
  if (GetEnvironmentVariableW(L"ENABLE_POWERSHELLCORE", nullptr, 0) <= 0 &&
      GetLastError() == ERROR_ENVVAR_NOT_FOUND && !selectcore) {
    SetConsoleTitle(L"Windows PowerShell");
    if (PowershellDesktop(psfile)) {
      return true;
    }
  }
  SetConsoleTitle(L"Pwsh");
  return PowershellCore(psfile);
}

/// ProgramW6432
/// ProgramFiles

/// %SystemRoot%/System32/WindowsPowerShell/v1.0/powershell.exe

bool EndsCaseWith(const wchar_t *s1, const wchar_t *s2) {
  auto l = wcslen(s1);
  auto l2 = wcslen(s2);
  return (l >= l2 ? (_wcsnicmp(s1 + (l - l2), s2, l2) == 0) : false);
}

bool PathEndsCaseWith(const wchar_t *s1, const wchar_t *s2) {
  if(EndsCaseWith(s1,L".exe")){
	auto l = wcslen(s1) - 4;
	auto l2 = wcslen(s2);
	return (l > l2 ? (_wcsnicmp(s1 + (l - l2), s2, l2) == 0) : false);
  }
  return EndsCaseWith(s1,s2);
}

int wmain(int argc, wchar_t **argv) {
  std::wstring psfile;
  bool selectcore=PathEndsCaseWith(argv[0], L"pwsh")||PathEndsCaseWith(argv[0], L"pwshex");
  if (!PowershellSelect(psfile,selectcore)) {
    MessageBoxW(nullptr, L"Please install Powershell", L"Powershell Not Found",
                MB_OK | MB_ICONERROR);
    return 1;
  }
  Arguments args;
  args.assign(psfile.c_str());
  for (int i = 1; i < argc; i++) {
    args.append(argv[i]);
  }
  PROCESS_INFORMATION pi;
  STARTUPINFO si;
  ZeroMemory(&si, sizeof(si));
  ZeroMemory(&pi, sizeof(pi));
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESHOWWINDOW;
  si.wShowWindow = SW_SHOW;
  if (CreateProcessW(nullptr, const_cast<wchar_t *>(args.str().c_str()), NULL,
                     NULL, FALSE, NORMAL_PRIORITY_CLASS, NULL, NULL, &si,
                     &pi) != TRUE) {
    MessageBoxW(nullptr, L"Please install Powershell", L"Create Process Error",
                MB_OK | MB_ICONERROR);
    return 1;
  }
  DWORD exitcode = 1;
  WaitForSingleObject(pi.hProcess, INFINITE);
  GetExitCodeProcess(pi.hProcess, &exitcode);
  CloseHandle(pi.hThread);
  CloseHandle(pi.hProcess);

  return exitcode;
}