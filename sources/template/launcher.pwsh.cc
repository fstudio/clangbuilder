#include <Shlwapi.h>
#include <Windows.h>

#define TARGET_SCRIPT_FILE L"@TARGET_SCRIPT_FILE"
// #define TARGET_SCRIPT_ARGS "upgrade --default" example
//@TARGET_SCRIPT_ARGS

size_t StringLength(const wchar_t *s) {
  const wchar_t *a;
  for (a = s; *s; s++)
    ;
  return s - a;
}

wchar_t *StringSearchW(const wchar_t *string, wchar_t ch) {
  while (*string && *string != (wchar_t)ch)
    string++;

  if (*string == (wchar_t)ch)
    return ((wchar_t *)string);
  return (NULL);
}

wchar_t *StringCopy(wchar_t *d, const wchar_t *s) {
  wchar_t *a = d;
  while ((*d++ = *s++) != 0)
    ;
  return a;
}

wchar_t *StringCat(wchar_t *destination, const wchar_t *source) {
  wchar_t *destination_it = destination;

  // Find the end of the destination string:
  while (*destination_it)
    ++destination_it;

  // Append the source string to the destination string:
  while ((*destination_it++ = *source++) != L'\0') {
  }

  return destination;
}

class StringBuffer {
public:
  StringBuffer() : m_capability(0), m_data(nullptr) {}
  StringBuffer(StringBuffer &&other) {
    m_data = other.m_data;
    other.m_data = nullptr;
    m_capability = other.m_capability;
    other.m_capability = 0;
    m_size = other.m_size;
    other.m_size = 0;
  }
  StringBuffer(size_t n) {
    m_data = (wchar_t *)HeapAlloc(GetProcessHeap(), 0, sizeof(wchar_t) * n);
    m_capability = n;
    m_size = 0;
  }
  ~StringBuffer() {
    if (m_data) {
      HeapFree(GetProcessHeap(), 0, m_data);
    }
  }
  StringBuffer &transfer(StringBuffer &&other) {
    m_data = other.m_data;
    other.m_data = nullptr;
    m_capability = other.m_capability;
    other.m_capability = 0;
    m_size = other.m_size;
    other.m_size = 0;
    return *this;
  }
  StringBuffer &append(const wchar_t *cstr) {
    auto l = StringLength(cstr);
    if (l > m_capability - m_size)
      return *this;
    StringCopy(m_data + m_size, cstr);
    m_size += l;
    return *this;
  }
  size_t capability() const { return m_capability; }
  size_t setsize(size_t sz) {
    if (m_size == 0)
      m_size = sz;
    return m_size;
  }
  const wchar_t *data() const {
    if (m_size < m_capability && m_size != 0) {
      m_data[m_size] = 0;
    }
    return m_data;
  }
  wchar_t *data() { return m_data; }

private:
  wchar_t *m_data;
  size_t m_capability;
  size_t m_size;
};

bool IsSpaceExists(const wchar_t *s) {
  for (; *s && *s != L' '; s++)
    ;
  return *s ? true : false;
}


bool GetPowerShellCore(StringBuffer &buf) {
  //

  return false;
}
///
bool GetClangbuilderRoot(LPWSTR buffer, size_t bufsize) {
  WCHAR xbuf[4096];
  GetModuleFileNameW(nullptr, buffer, bufsize);
  for (int i = 0; i < 5; i++) {
    if (!PathRemoveFileSpecW(buffer)) {
      return false;
    }
    StringCopy(xbuf, buffer);
    StringCat(xbuf, L"\\bin\\ClangbuilderTarget.ps1");
    if (PathFileExistsW(xbuf)) {
      return true;
    }
  }
  return true;
}

bool BuildArgs(StringBuffer &cmd) {
  int Argc = 0;
  auto Argv = CommandLineToArgvW(GetCommandLineW(), &Argc);
  if (!Argv) {
    return false;
  }
  StringBuffer buffer(0x8000);
  WCHAR cbroot[4096] = {0};
  if (!GetPowerShellCore(buffer)) {
    MessageBoxW(nullptr, L"Please install powershell core and retry !",
                L"PowerShell Core not installed", MB_OK | MB_ICONERROR);
    return false;
  }
  if (!GetClangbuilderRoot(cbroot, 4096)) {
    MessageBoxW(nullptr, L"Please reinstall clangbuilder !",
                L"Invalid clangbuilder installed", MB_OK | MB_ICONERROR);
    return false;
  }
  buffer.append(L" -NoProfile -NoLogo -ExecutionPolicy unrestricted -File \"")
      .append(cbroot)
      .append(L"\\")
      .append(TARGET_SCRIPT_FILE)
      .append(L"\" ");
#ifdef TARGET_SCRIPT_ARGS
  buffer.append(TARGET_SCRIPT_ARGS).append(L" ");
#endif

  for (int i = 1; i < Argc; i++) {
    if (IsSpaceExists(Argv[i])) {
      buffer.append(L"\"").append(Argv[i]).append(L"\" ");
    } else {
      buffer.append(Argv[i]).append(L" ");
    }
  }
  cmd.transfer(reinterpret_cast<StringBuffer &&>(buffer));
  LocalFree(Argv);
  return true;
}

int wmain() {
  STARTUPINFOW siw;
  GetStartupInfoW(&siw);

  StringBuffer cmd;
  if (!BuildArgs(cmd)) {
    return 1;
  }
  STARTUPINFOW si;
  PROCESS_INFORMATION pi;
  SecureZeroMemory(&si, sizeof(si));
  SecureZeroMemory(&pi, sizeof(pi));
  si.cb = sizeof(si);
  if (!CreateProcessW(nullptr, cmd.data(), nullptr, nullptr, FALSE,
                      CREATE_UNICODE_ENVIRONMENT, nullptr, nullptr, &si, &pi)) {
    return 1;
  }
  CloseHandle(pi.hThread);
  WaitForSingleObject(pi.hProcess, INFINITE);
  DWORD exitCode;
  GetExitCodeProcess(pi.hProcess, &exitCode);
  ExitProcess(exitCode);
}
