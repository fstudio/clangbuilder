////////////////////////
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winnt.h>
#include <Shellapi.h>
#include <Shlobj.h>
#include <stdio.h>
#include <stdlib.h>

#define BLASTLINK_TARGET L"@LINK_TEMPLATE_TARGET"

wchar_t *wcharmalloc(size_t n) {
  return reinterpret_cast<wchar_t *>(
      HeapAlloc(GetProcessHeap(), 0, sizeof(wchar_t) * n));
}

void wcharfree(wchar_t *p) { HeapFree(GetProcessHeap(), 0, p); }

void *xmemcpy(void *dest, const void *src, size_t n) {
  unsigned char *d = reinterpret_cast<unsigned char *>(dest);
  const unsigned char *s = reinterpret_cast<const unsigned char *>(src);
  for (; n; n--)
    *d++ = *s++;
  return dest;
}
inline size_t stringlength(const wchar_t *s) {
  const wchar_t *a = s;
  for (; *a != 0; a++) {
    ;
  }
  return a - s;
}

inline void zeromem(wchar_t *p, size_t len) {
  for (size_t i = 0; i < len; i++) {
    p[i] = 0;
  }
}

struct escapehelper {
  ~escapehelper() {
    if (buffer != nullptr) {
      wcharfree(buffer);
    }
  }
  wchar_t *buffer{nullptr};
  const wchar_t *escape(const wchar_t *s) {
    auto len = stringlength(s);
    if (len == 0) {
      return L"\"\"";
    }
    auto n = len;
    auto hasSpace = false;
    for (size_t i = 0; i < len; i++) {
      switch (s[i]) {
      case L'"':
      case L'\\':
        n++;
        break;
      case L' ':
      case L'\t':
        hasSpace = true;
        break;
      default:
        break;
      }
    }
    if (hasSpace) {
      n += 2;
    }
    if (n == len) {
      return s;
    }
    buffer = wcharmalloc(n + 1);
    size_t j = 0;
    if (hasSpace) {
      buffer[j] = L'"';
      j++;
    }
    int slashes = 0;
    for (size_t i = 0; i < len; i++) {
      switch (s[i]) {
      default:
        slashes = 0;
        buffer[j] = s[i];
        break;
      case L'\\':
        slashes++;
        buffer[j] = s[i];
        break;
      case L'"':
        for (; slashes > 0; slashes--) {
          buffer[j] = L'\\';
          j++;
        }
        buffer[j] = L'\\';
        j++;
        buffer[j] = s[i];
        break;
      }
      j++;
    }
    if (hasSpace) {
      for (; slashes > 0; slashes--) {
        buffer[j] = L'\\';
        j++;
      }
      buffer[j] = L'"';
      j++;
    }
    buffer[j] = L'\0';
    return buffer;
  }
};

class ArgvBuffer {
public:
  ArgvBuffer() = default;
  ArgvBuffer(size_t n) {
    reserve(n); //
  }
  ~ArgvBuffer() {
    if (data_) {
      wcharfree(data_);
    }
  }
  void reserve(size_t n) {
    if (n <= capability_) {
      return;
    }
    auto np = wcharmalloc(n);
    zeromem(np, n);
    if (data_ != nullptr) {
      xmemcpy(np, data_, size_ * sizeof(wchar_t)); ///
      wcharfree(data_);
    }
    capability_ = n;
    data_ = np;
  }

  ArgvBuffer &assign(const wchar_t *a0) {
    escapehelper es;
    auto p = es.escape(a0);
    auto l = stringlength(p);
    if (l + 1 >= capability_) {
      reserve(l + 1);
    }
    xmemcpy(data_, p, l * sizeof(wchar_t));
    data_[l] = 0;
    size_ = l;
    return *this;
  }

  ArgvBuffer &append(const wchar_t *ax) {
    escapehelper es;
    auto p = es.escape(ax);
    auto l = stringlength(p);
    if (l + size_ + 2 >= capability_) {
      reserve(l + size_ + 2);
    }
    data_[size_] = L' ';
    size_++;
    xmemcpy(data_ + size_, p, l * sizeof(wchar_t));
    size_ += l;
    data_[size_] = L'\0';
    return *this;
  }
  const wchar_t *data() const { return data_; }
  wchar_t *data() { return data_; }
  size_t size() const { return size_; }

private:
  wchar_t *data_ = nullptr;
  size_t capability_{0};
  size_t size_{0};
};

bool BuildArgs(const wchar_t *target, ArgvBuffer &ab) {
  int Argc = 0;
  auto Argv = CommandLineToArgvW(GetCommandLineW(), &Argc);
  if (!Argv) {
    return false;
  }
  ab.reserve(0x8000);
  ab.assign(target);
  for (int i = 1; i < Argc; i++) {
    ab.append(Argv[i]);
  }
  LocalFree(Argv);
  return true;
}

int LinkToApp(const wchar_t *target) {
  STARTUPINFOW siw;
  GetStartupInfoW(&siw);

  ArgvBuffer ab;
  if (!BuildArgs(target, ab)) {
    return -1;
  }
  STARTUPINFOW si;
  PROCESS_INFORMATION pi;
  SecureZeroMemory(&si, sizeof(si));
  SecureZeroMemory(&pi, sizeof(pi));
  si.cb = sizeof(si);
  if (!CreateProcessW(nullptr, ab.data(), nullptr, nullptr, FALSE,
                      CREATE_UNICODE_ENVIRONMENT, nullptr, nullptr, &si, &pi)) {
    return -1;
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

int wmain() {
  ///
  ExitProcess(LinkToApp(BLASTLINK_TARGET));
}