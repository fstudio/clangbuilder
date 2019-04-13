///////
#ifndef CLANGBUILDER_STRING_HPP
#define CLANGBUILDER_STRING_HPP
#include <string>
#include <string_view>
#include <algorithm>
#include <cstring>

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <Windows.h>

namespace base {

// StrContains()
//
// Returns whether a given string `haystack` contains the substring `needle`.
inline bool StrContains(std::wstring_view haystack, std::wstring_view needle) {
  return haystack.find(needle, 0) != std::wstring_view::npos;
}

// StartsWith()
//
// Returns whether a given string `text` begins with `prefix`.
inline bool StartsWith(std::wstring_view text, std::wstring_view prefix) {
  return prefix.empty() ||
         (text.size() >= prefix.size() &&
          wmemcmp(text.data(), prefix.data(), prefix.size()) == 0);
}

// EndsWith()
//
// Returns whether a given string `text` ends with `suffix`.
inline bool EndsWith(std::wstring_view text, std::wstring_view suffix) {
  return suffix.empty() || (text.size() >= suffix.size() &&
                            wmemcmp(text.data() + (text.size() - suffix.size()),
                                    suffix.data(), suffix.size()) == 0);
}

inline bool ConsumePrefix(std::wstring_view *str, std::wstring_view expected) {
  if (!StartsWith(*str, expected)) {
    return false;
  }
  str->remove_prefix(expected.size());
  return true;
}
// ConsumeSuffix()
//
// Strips the `expected` suffix from the end of the given string, returning
// `true` if the strip operation succeeded or false otherwise.
//
// Example:
//
//   std::wstring_view input("abcdef");
//   EXPECT_TRUE(absl::ConsumeSuffix(&input, "def"));
//   EXPECT_EQ(input, "abc");
inline bool ConsumeSuffix(std::wstring_view *str, std::wstring_view expected) {
  if (!EndsWith(*str, expected)) {
    return false;
  }
  str->remove_suffix(expected.size());
  return true;
}

// StripPrefix()
//
// Returns a view into the input string 'str' with the given 'prefix' removed,
// but leaving the original string intact. If the prefix does not match at the
// start of the string, returns the original string instead.
inline std::wstring_view StripPrefix(std::wstring_view str,
                                     std::wstring_view prefix) {
  if (StartsWith(str, prefix)) {
    str.remove_prefix(prefix.size());
  }
  return str;
}

// StripSuffix()
//
// Returns a view into the input string 'str' with the given 'suffix' removed,
// but leaving the original string intact. If the suffix does not match at the
// end of the string, returns the original string instead.
inline std::wstring_view StripSuffix(std::wstring_view str,
                                     std::wstring_view suffix) {
  if (EndsWith(str, suffix)) {
    str.remove_suffix(suffix.size());
  }
  return str;
}

inline std::wstring
CatStringViews(std::initializer_list<std::wstring_view> pieces) {
  std::wstring result;
  size_t total_size = 0;
  for (const std::wstring_view piece : pieces) {
    total_size += piece.size();
  }
  result.resize(total_size);

  wchar_t *const begin = &*result.begin();
  wchar_t *out = begin;
  for (const std::wstring_view piece : pieces) {
    const size_t this_size = piece.size();
    wmemcpy(out, piece.data(), this_size);
    out += this_size;
  }
  return result;
}

// Windows shlapi has StrCat
inline std::wstring StringCat() { return std::wstring(); }
inline std::wstring StringCat(std::wstring_view sv) { return std::wstring(sv); }

template <typename... Args>
std::wstring StringCat(std::wstring_view v0, const Args &... args) {
  return CatStringViews({v0, args...});
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

// ToNarrow UTF-16 to UTF-8
inline std::string ToNarrow(std::wstring_view uw) {
  auto l = WideCharToMultiByte(CP_UTF8, 0, uw.data(), (int)uw.size(), nullptr,
                               0, nullptr, nullptr);
  std::string ustr;
  ustr.resize(l + 1);
  auto N = WideCharToMultiByte(CP_UTF8, 0, uw.data(), (int)uw.size(),
                               ustr.data(), l + 1, nullptr, nullptr);
  ustr.resize(N);
  return ustr;
}

inline std::wstring ToWide(std::string_view u8) {
  std::wstring wstr;
  auto N =
      MultiByteToWideChar(CP_UTF8, 0, u8.data(), (DWORD)u8.size(), nullptr, 0);
  if (N > 0) {
    wstr.resize(N);
    MultiByteToWideChar(CP_UTF8, 0, u8.data(), (DWORD)u8.size(), &wstr[0], N);
  }
  return wstr;
}

} // namespace base

#endif