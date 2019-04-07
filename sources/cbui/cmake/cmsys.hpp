///////
#ifndef CMSYS_HPP
#define CMSYS_HPP

#include <cstdio>
#include <cstdlib>
#include <wchar.h>
#include <string>
#include <string_view>
#include <fstream>
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

namespace cmsys {
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

inline std::wstring TrimWhitespace(const std::wstring &s) {
  auto it = s.begin();
  while (it != s.end() && isspace(*it)) {
    ++it;
  }
  if (it == s.end()) {
    return L"";
  }
  std::wstring::const_iterator stop = s.end() - 1;
  while (isspace(*stop)) {
    --stop;
  }
  return std::wstring(it, stop + 1);
}

inline bool ComparePath(std::wstring_view a, std::wstring_view b) {
  return UnCaseEqual(a, b);
}

inline bool GetLineFromStream(std::istream &is, std::string &line,
                              bool *has_newline = nullptr,
                              long sizeLimit = -1) {
  // Start with an empty line.
  line = "";

  // Early short circuit return if stream is no good. Just return
  // false and the empty line. (Probably means caller tried to
  // create a file stream with a non-existent file name...)
  //
  if (!is) {
    if (has_newline) {
      *has_newline = false;
    }
    return false;
  }

  std::getline(is, line);
  bool haveData = !line.empty() || !is.eof();
  if (!line.empty()) {
    // Avoid storing a carriage return character.
    if (line.back() == '\r') {
      line.resize(line.size() - 1);
    }

    // if we read too much then truncate the buffer
    if (sizeLimit >= 0 && line.size() >= static_cast<size_t>(sizeLimit)) {
      line.resize(sizeLimit);
    }
  }

  // Return the results.
  if (has_newline) {
    *has_newline = !is.eof();
  }
  return haveData;
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

} // namespace cmsys

#endif