#ifndef CBUI_BASE_HPP
#define CBUI_BASE_HPP
#pragma once
#include "sdkver.hpp"
#ifndef _WINDOWS_
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN //
#endif
#include <windows.h>
#endif
#include <string>
#include <string_view>
#include <optional>
#include <vector>

namespace base {
// final_act
// https://github.com/Microsoft/GSL/blob/ebe7ebfd855a95eb93783164ffb342dbd85cbc27/include/gsl/gsl_util#L85-L89

inline std::wstring catsv(std::initializer_list<std::wstring_view> pieces) {
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

inline std::wstring strcat() { return std::wstring(); }
inline std::wstring strcat(std::wstring_view sv) { return std::wstring(sv); }

template <typename... Args>
std::wstring strcat(std::wstring_view v0, const Args &... args) {
  return catsv({v0, args...});
}

template <class F> class final_act {
public:
  explicit final_act(F f) noexcept : f_(std::move(f)), invoke_(true) {}

  final_act(final_act &&other) noexcept
      : f_(std::move(other.f_)), invoke_(other.invoke_) {
    other.invoke_ = false;
  }

  final_act(const final_act &) = delete;
  final_act &operator=(const final_act &) = delete;

  ~final_act() noexcept {
    if (invoke_)
      f_();
  }

private:
  F f_;
  bool invoke_;
};

// finally() - convenience function to generate a final_act
template <class F> inline final_act<F> finally(const F &f) noexcept {
  return final_act<F>(f);
}

template <class F> inline final_act<F> finally(F &&f) noexcept {
  return final_act<F>(std::forward<F>(f));
}
struct error_code {
  std::wstring message;
  long code{NO_ERROR};
  explicit operator bool() const noexcept { return code != NO_ERROR; }
};

inline error_code make_error_code(int val, std::wstring_view msg) {
  return error_code{std::wstring(msg), val};
}

inline error_code make_error_code(std::wstring_view msg) {
  return error_code{std::wstring(msg), -1};
}

template <typename... Args>
inline error_code strcat_error_code(std::wstring_view v0,
                                    const Args &... args) {
  auto msg = catsv({v0, args...});
  return error_code{std::move(msg), -1};
}

inline std::wstring system_error_dump(DWORD ec) {
  LPWSTR buf = nullptr;
  auto rl = FormatMessageW(
      FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, nullptr, ec,
      MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL), (LPWSTR)&buf, 0, nullptr);
  if (rl == 0) {
    return L"FormatMessageW error";
  }
  std::wstring msg(buf, rl);
  LocalFree(buf);
  return msg;
}

inline error_code make_system_error_code() {
  error_code ec;
  ec.code = GetLastError();
  ec.message = system_error_dump(ec.code);
  return ec;
}
} // namespace base

#endif