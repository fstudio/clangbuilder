///////
#ifndef CLANGBUILDER_STRING_HPP
#define CLANGBUILDER_STRING_HPP
#include <string>
#include <string_view>
#include <cstring>

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
  return prefix.empty() || (text.size() >= prefix.size() &&
                            memcmp(text.data(), prefix.data(),
                                   prefix.size() * sizeof(wchar_t)) == 0);
}

// EndsWith()
//
// Returns whether a given string `text` ends with `suffix`.
inline bool EndsWith(std::wstring_view text, std::wstring_view suffix) {
  return suffix.empty() ||
         (text.size() >= suffix.size() &&
          memcmp(text.data() + (text.size() - suffix.size()), suffix.data(),
                 suffix.size() * sizeof(wchar_t)) == 0);
}

inline bool ConsumePrefix(std::wstring_view *str, std::wstring_view expected) {
  if (!StartsWith(*str, expected))
    return false;
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
  if (!EndsWith(*str, expected))
    return false;
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
  if (StartsWith(str, prefix))
    str.remove_prefix(prefix.size());
  return str;
}

// StripSuffix()
//
// Returns a view into the input string 'str' with the given 'suffix' removed,
// but leaving the original string intact. If the suffix does not match at the
// end of the string, returns the original string instead.
inline std::wstring_view StripSuffix(std::wstring_view str,
                                     std::wstring_view suffix) {
  if (EndsWith(str, suffix))
    str.remove_suffix(suffix.size());
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

inline std::wstring StrCat() { return std::wstring(); }
inline std::wstring StrCat(std::wstring_view sv) { return std::wstring(sv); }

template <typename... Args>
std::wstring StrCat(std::wstring_view v0, const Args &... args) {
  return CatStringViews({v0, args...});
}

} // namespace base

#endif