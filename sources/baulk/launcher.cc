//
#include <bela/pe.hpp>
#include <bela/subsitute.hpp>
#include "baulk.hpp"
#include "rcwriter.hpp"

namespace baulk {
//
namespace internal {
constexpr std::wstring_view consoletemplete = LR"(#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winnt.h>
inline constexpr size_t StringLength(const wchar_t *s) {
  const wchar_t *a = s;
  for (; *a != 0; a++) {
    ;
  }
  return a - s;
}
inline void StringZero(wchar_t *p, size_t len) {
  for (size_t i = 0; i < len; i++) {
    p[i] = 0;
  }
}
inline void *StringCopy(wchar_t *dest, const wchar_t *src, size_t n) {
  auto d = dest;
  for (; n; n--) {
    *d++ = *src++;
  }
  return dest;
}
inline wchar_t *StringAllocate(size_t count) {
  return reinterpret_cast<wchar_t *>(
      HeapAlloc(GetProcessHeap(), 0, sizeof(wchar_t) * count));
}
inline wchar_t *StringDup(const wchar_t *s) {
  auto l = StringLength(s);
  auto ds = StringAllocate(l + 1);
  StringCopy(ds, s, l);
  ds[l] = 0;
  return ds;
}
inline void StringFree(wchar_t *p) {
  HeapFree(GetProcessHeap(), 0, p);
}
int LinkToApp(const wchar_t *target) {
  STARTUPINFOW si;
  PROCESS_INFORMATION pi;
  SecureZeroMemory(&si, sizeof(si));
  SecureZeroMemory(&pi, sizeof(pi));
  si.cb = sizeof(si);
  auto cmdline = StringDup(GetCommandLineW());
  if (!CreateProcessW(BLASTLINK_TARGET, cmdline, nullptr, nullptr, FALSE,
                      CREATE_UNICODE_ENVIRONMENT, nullptr, nullptr, &si, &pi)) {
    StringFree(cmdline);
    return -1;
  }
  StringFree(cmdline);
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
  constexpr const wchar_t *target=L"$0";
  ExitProcess(LinkToApp(target));
}
)";

constexpr std::wstring_view windowstemplate = LR"(#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <winnt.h>
#include <Shellapi.h>
#include <Shlobj.h>
#include <cstddef>
inline constexpr size_t StringLength(const wchar_t *s) {
  const wchar_t *a = s;
  for (; *a != 0; a++) {
    ;
  }
  return a - s;
}
inline void StringZero(wchar_t *p, size_t len) {
  for (size_t i = 0; i < len; i++) {
    p[i] = 0;
  }
}
inline void *StringCopy(wchar_t *dest, const wchar_t *src, size_t n) {
  auto d = dest;
  for (; n; n--) {
    *d++ = *src++;
  }
  return dest;
}
inline wchar_t *StringAllocate(size_t count) {
  return reinterpret_cast<wchar_t *>(
      HeapAlloc(GetProcessHeap(), 0, sizeof(wchar_t) * count));
}
inline wchar_t *StringDup(const wchar_t *s) {
  auto l = StringLength(s);
  auto ds = StringAllocate(l + 1);
  StringCopy(ds, s, l);
  ds[l] = 0;
  return ds;
}
inline void StringFree(wchar_t *p) {
  HeapFree(GetProcessHeap(), 0, p);
}
int LinkToApp(const wchar_t *target) {
  STARTUPINFOW si;
  PROCESS_INFORMATION pi;
  SecureZeroMemory(&si, sizeof(si));
  SecureZeroMemory(&pi, sizeof(pi));
  si.cb = sizeof(si);
  auto cmdline = StringDup(GetCommandLineW());
  if (!CreateProcessW(BLASTLINK_TARGET, cmdline, nullptr, nullptr, FALSE,
                      CREATE_UNICODE_ENVIRONMENT, nullptr, nullptr, &si, &pi)) {
    StringFree(cmdline);
    return -1;
  }
  StringFree(cmdline);
  CloseHandle(pi.hThread);
  CloseHandle(pi.hProcess);
  return 0;
}
int WINAPI wWinMain(HINSTANCE, HINSTANCE, LPWSTR, int) {
  constexpr const wchar_t *target=L"$0";
  ExitProcess(LinkToApp(target));
}
)";
} // namespace internal

std::wstring GenerateLinkSource(std::wstring_view target,
                                bela::pe::Subsystem subs) {
  if (subs == bela::pe::Subsystem::CUI) {
    return bela::Substitute(internal::consoletemplete, target);
  }
  return bela::Substitute(internal::windowstemplate);
}

bool MakeLaunchers(std::wstring_view root, const baulk::Package &pkg,
                   bela::error_code &ec) {
  auto pkgroot = bela::StringCat(root, L"\\pkg\\", pkg.name);
  return false;
}

bool MakeSymlinks(std::wstring_view root, const baulk::Package &pkg,
                  bela::error_code &ec) {
  auto pkgroot = bela::StringCat(root, L"\\pkg\\", pkg.name);
  return false;
}

bool MakeLinks(std::wstring_view root, const baulk::Package &pkg,
               bela::error_code &ec) {
  if (!pkg.links.empty() && !MakeSymlinks(root, pkg, ec)) {
    return false;
  }
  if (!pkg.launchers.empty() && !MakeLaunchers(root, pkg, ec)) {
    return false;
  }
  return true;
}
} // namespace baulk
