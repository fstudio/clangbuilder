////////////////////////
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winnt.h>
#include <Shellapi.h>
#include <Shlobj.h>

#define BLASTLINK_TARGET L"@LINK_TEMPLATE_TARGET"

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
  bool append(const wchar_t *cstr) {
    auto l = StringLength(cstr);
    if (l > m_capability - m_size)
      return false;
    StringCopy(m_data + m_size, cstr);
    m_size += l;
    return true;
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

bool BuildArgs(const wchar_t *target, StringBuffer &cmd) {
  int Argc = 0;
  auto Argv = CommandLineToArgvW(GetCommandLineW(), &Argc);
  if (!Argv) {
    return false;
  }
  StringBuffer buffer(0x8000);

  if (IsSpaceExists(target)) {
    buffer.append(L"\"");
    buffer.append(target);
    buffer.append(L"\" ");
  } else {
    buffer.append(target);
    buffer.append(L" ");
  }
  for (int i = 1; i < Argc; i++) {
    if (IsSpaceExists(Argv[i])) {
      buffer.append(L"\"");
      buffer.append(Argv[i]);
      buffer.append(L"\" ");
    } else if (StringLength(Argv[i]) == 0) {
      buffer.append(L"\"\" ");
    } else {
      buffer.append(Argv[i]);
      buffer.append(L" ");
    }
  }
  cmd.transfer(reinterpret_cast<StringBuffer &&>(buffer));
  LocalFree(Argv);
  return true;
}

int LinkToApp(const wchar_t *target) {
  STARTUPINFOW siw;
  GetStartupInfoW(&siw);
  StringBuffer cmd;
  if (!BuildArgs(target, cmd)) {
    return -1;
  }
  STARTUPINFOW si;
  PROCESS_INFORMATION pi;
  SecureZeroMemory(&si, sizeof(si));
  SecureZeroMemory(&pi, sizeof(pi));
  si.cb = sizeof(si);
  if (!CreateProcessW(nullptr, cmd.data(), nullptr, nullptr, FALSE,
                      CREATE_UNICODE_ENVIRONMENT, nullptr, nullptr, &si, &pi)) {
    return -1;
  }
  CloseHandle(pi.hThread);
  CloseHandle(pi.hProcess);
  return 0;
}

int WINAPI wWinMain(HINSTANCE, HINSTANCE, LPWSTR, int) {
  ///
  ExitProcess(LinkToApp(BLASTLINK_TARGET));
}