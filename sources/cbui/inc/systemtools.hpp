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
#include <fstream>
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

namespace clangbuilder {
constexpr const size_t maxsize = 0x8000;
constexpr const size_t maxpathsize = 256;
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

// Returns std::string_view with whitespace stripped from the beginning of the
// given string_view.
inline std::string_view StripLeadingAsciiWhitespace(std::string_view str) {
  auto it = std::find_if_not(str.begin(), str.end(), std::isspace);
  return str.substr(it - str.begin());
}

// Returns std::string_view with whitespace stripped from the end of the given
// string_view.
inline std::string_view StripTrailingAsciiWhitespace(std::string_view str) {
  auto it = std::find_if_not(str.rbegin(), str.rend(), std::isspace);
  return str.substr(0, str.rend() - it);
}

// Returns std::string_view with whitespace stripped from both ends of the
// given string_view.
inline std::string_view StripAsciiWhitespace(std::string_view str) {
  return StripTrailingAsciiWhitespace(StripLeadingAsciiWhitespace(str));
}

////////////// wstring_view
// Returns std::wstring_view with whitespace stripped from the beginning of the
// given string_view.
inline std::wstring_view StripLeadingAsciiWhitespace(std::wstring_view str) {
  auto it = std::find_if_not(str.begin(), str.end(), std::isspace);
  return str.substr(it - str.begin());
}

// Returns std::wstring_view with whitespace stripped from the end of the given
// string_view.
inline std::wstring_view StripTrailingAsciiWhitespace(std::wstring_view str) {
  auto it = std::find_if_not(str.rbegin(), str.rend(), std::isspace);
  return str.substr(0, str.rend() - it);
}

// Returns std::wstring_view with whitespace stripped from both ends of the
// given string_view.
inline std::wstring_view StripAsciiWhitespace(std::wstring_view str) {
  return StripTrailingAsciiWhitespace(StripLeadingAsciiWhitespace(str));
}

inline bool FileIsDirectory(std::wstring_view dir) {
  if (dir.empty()) {
    return false;
  }
  auto attr = GetFileAttributesW(dir.data());
  if (attr != INVALID_FILE_ATTRIBUTES) {
    return (attr & FILE_ATTRIBUTE_DIRECTORY) != 0;
  }
  return false;
}

std::wstring utf8towide(std::string_view u8) {
  std::wstring wstr;
  auto N =
      MultiByteToWideChar(CP_UTF8, 0, u8.data(), (DWORD)u8.size(), nullptr, 0);
  if (N > 0) {
    wstr.resize(N);
    MultiByteToWideChar(CP_UTF8, 0, u8.data(), (DWORD)u8.size(), &wstr[0], N);
  }
  return wstr;
}

} // namespace clangbuilder

#endif