///////
#ifndef CBUI_SYSTEMTOOLS_HPP
#define CBUI_SYSTEMTOOLS_HPP

#include <cstdio>
#include <cstdlib>
#include <wchar.h>
#include <algorithm>
#include <string>
#include <string_view>
#include <cctype>
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

namespace clangbuilder {
constexpr const size_t maxsize = 0x8000;
constexpr const size_t maxpathsize = 256;

struct FD {
  FD() = default;
  FD(const FD &) = delete;
  FD &operator=(const FD &) = delete;
  FD(FILE *f) : fd(f) {
    //
  }
  ~FD() {
    if (fd != nullptr) {
      fclose(fd);
    }
  }
  FD &operator=(FILE *f) {
    if (fd != nullptr) {
      fclose(fd);
    }
    fd = f;
    return *this;
  }
  explicit operator bool() const noexcept { return fd != nullptr; }
  FILE *P() const { return fd; }
  FILE *fd{nullptr};
};

struct WidnowsFD {
  WidnowsFD() = default;
  WidnowsFD(const WidnowsFD &) = delete;
  WidnowsFD &operator=(const WidnowsFD &) = delete;
  WidnowsFD(HANDLE h) : hFile(h) {
    //
  }
  ~WidnowsFD() {
    if (hFile != INVALID_HANDLE_VALUE) {
      CloseHandle(hFile);
    }
  }
  WidnowsFD &operator=(HANDLE h) {
    if (hFile != INVALID_HANDLE_VALUE) {
      CloseHandle(hFile);
    }
    hFile = h;
    return *this;
  }
  explicit operator bool() const noexcept {
    return hFile != INVALID_HANDLE_VALUE;
  }
  operator HANDLE() const { return hFile; }
  HANDLE hFile{INVALID_HANDLE_VALUE};
};

inline bool GetEnvString(const wchar_t *key, std::wstring &val) {
  val.resize(maxsize);
  auto size = maxsize;
  if (_wgetenv_s(&size, val.data(), size, key) != 0) {
    val.clear();
    return false;
  }
  val.resize(size);
  return true;
}
inline bool GetEnv(const wchar_t *key, std::wstring &val) {
  val.resize(256);
  auto size = maxpathsize;
  if (_wgetenv_s(&size, val.data(), size, key) != 0) {
    val.clear();
    return false;
  }
  val.resize(size);
  return true;
}
inline bool UnCaseEqual(std::wstring_view a, std::wstring_view b) {
  if (a.size() != b.size()) {
    return false;
  }
  for (size_t i = 0; i < a.size(); i++) {
    if (_tolower(a[i]) != _tolower(b[i])) {
      return false;
    }
  }
  return true;
}

inline bool IsDir(std::wstring_view dir) {
  if (dir.empty()) {
    return false;
  }
  auto attr = GetFileAttributesW(dir.data());
  return attr != INVALID_FILE_ATTRIBUTES &&
         ((attr & FILE_ATTRIBUTE_DIRECTORY) != 0);
}

inline bool LookupVersionFromFile(std::wstring_view file, std::wstring &ver) {
  WidnowsFD fd =
      CreateFileW(file.data(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
                  nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (!fd) {
    return false;
  }
  uint8_t buf[4096] = {0}; // MUST U8
  DWORD dwr = 0;
  if (ReadFile(fd, buf, 4096, &dwr, nullptr) != TRUE || dwr < 3) {
    return false;
  }
  // UTF-16 LE
  if (buf[0] == 0xFF && buf[1] == 0xFE) {
    auto w = reinterpret_cast<wchar_t *>(buf + 2);
    auto l = (dwr - 2) / 2;
    ver.assign(w, l);
    w[l] = 0;
    return true;
  }
  // UTF-16 BE
  if (buf[0] == 0xFE && buf[1] == 0xFF) {
    auto w = reinterpret_cast<wchar_t *>(buf + 2);
    auto l = (dwr - 2) / 2;
    decltype(l) i = 0;
    for (; i < l; i++) {
      ver.push_back(_byteswap_ushort(w[i])); // Windows LE
    }
    return true;
  }
  // UTF-8 BOM
  if (buf[0] == 0xEF && buf[1] == 0xBB && buf[2] == 0xBF) {
    auto p = reinterpret_cast<char *>(buf + 3);
    std::string_view s(p, dwr - 3);
    ver = base::ToWide(s);
    return true;
  }
  // UTF-8 (ASCII)
  auto p = reinterpret_cast<char *>(buf);
  std::string_view s(p, dwr);
  ver = base::ToWide(s);
  return true;
}

} // namespace clangbuilder

#endif