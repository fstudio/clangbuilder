/// symlink
#include "blast.hpp"

#ifndef SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE
#define SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE 0x02
#endif

struct RegKeyHelper {
  ~RegKeyHelper() {
    if (hKey != nullptr) {
      RegCloseKey(hKey);
    }
  }
  HKEY hKey{nullptr};
};

bool IsWindowsVersionOrGreaterEx(WORD wMajorVersion, WORD wMinorVersion,
                                 DWORD buildNumber) {
  const wchar_t *currentVersion =
      LR"(SOFTWARE\Microsoft\Windows NT\CurrentVersion)";
  RegKeyHelper key;
  if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, currentVersion, 0, KEY_READ,
                    &(key.hKey)) != ERROR_SUCCESS) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"error: %s\n", err.message());
    return false;
  }
  DWORD wMajor, wMinor;
  DWORD type = 0;
  DWORD dwSizeM = sizeof(DWORD);
  if (RegGetValueW(key.hKey, nullptr, L"CurrentMajorVersionNumber",
                   RRF_RT_DWORD, &type, &wMajor, &dwSizeM) != ERROR_SUCCESS) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"error: %s\n", err.message());
    return false;
  }
  dwSizeM = sizeof(DWORD);
  if (RegGetValueW(key.hKey, nullptr, L"CurrentMinorVersionNumber",
                   RRF_RT_DWORD, &type, &wMinor, &dwSizeM) != ERROR_SUCCESS) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"error: %s\n", err.message());
    return false;
  }
  WCHAR buffer[32];
  DWORD dwSize = sizeof(buffer);
  if (RegGetValueW(key.hKey, nullptr, L"CurrentBuildNumber", RRF_RT_REG_SZ,
                   &type, buffer, &dwSize) != ERROR_SUCCESS) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"error: %s\n", err.message());
    return false;
  }
  wchar_t *w;
  auto bn = wcstol(buffer, &w, 10);
  if (wMajor < wMajorVersion) {
    return false;
  }
  if (wMajor > wMajorVersion) {
    return true;
  }
  if (wMinor > wMinorVersion) {
    return true;
  }
  if (wMinor < wMinorVersion) {
    return false;
  }
  return ((DWORD)bn >= buildNumber);
}

inline bool IsUserAdministratorsGroup()
/*++
Routine Description: This routine returns TRUE if the caller's
process is a member of the Administrators local group. Caller is NOT
expected to be impersonating anyone and is expected to be able to
open its own process and process token.
Arguments: None.
Return Value:
TRUE - Caller has Administrators local group.
FALSE - Caller does not have Administrators local group. --
*/
{
  BOOL b;
  SID_IDENTIFIER_AUTHORITY NtAuthority = SECURITY_NT_AUTHORITY;
  PSID AdministratorsGroup;
  b = AllocateAndInitializeSid(&NtAuthority, 2, SECURITY_BUILTIN_DOMAIN_RID,
                               DOMAIN_ALIAS_RID_ADMINS, 0, 0, 0, 0, 0, 0,
                               &AdministratorsGroup);
  if (b) {
    if (!CheckTokenMembership(NULL, AdministratorsGroup, &b)) {
      b = FALSE;
    }
    FreeSid(AdministratorsGroup);
  }

  return b == TRUE;
}

int AdministratorsElevateWait() {
  SHELLEXECUTEINFOW info;
  ZeroMemory(&info, sizeof(info));
  std::wstring exeself(32767, L'\0');
  if (!GetModuleFileNameW(nullptr, &exeself[0], 32767) == 0) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"GetModuleFileNameW: %s\n", err.message());
    return 1;
  }
  Arguments args;
  for (int i = 1; i < __argc; i++) {
    args.append(__wargv[i]);
  }
  info.lpFile = &exeself[0];
  info.lpParameters = args.str().data();
  info.lpVerb = L"runas";
  info.cbSize = sizeof(info);
  info.hwnd = NULL;
  info.nShow = SW_SHOWNORMAL;
  info.fMask = SEE_MASK_DEFAULT | SEE_MASK_NOCLOSEPROCESS;
  info.lpDirectory = nullptr;
  if (!ShellExecuteExW(&info)) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"GetFullPathNameW: %s\n", err.message());
    return 1;
  }
  WaitForSingleObject(info.hProcess, INFINITE);
  DWORD dwExit = 0;
  GetExitCodeProcess(info.hProcess, &dwExit);
  CloseHandle(info.hProcess);
  return dwExit;
}

int symlink(const wchar_t *src, const wchar_t *target) {
  DWORD dwflags = 0;
  if (IsWindowsVersionOrGreaterEx(10, 0, 14972)) {
    dwflags = SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE;
  } else {
    if (!IsUserAdministratorsGroup()) {
      return AdministratorsElevateWait();
    }
  }
  if (GetFileAttributesW(src) == INVALID_FILE_ATTRIBUTES) {
    fwprintf(stderr, L"file: %s not exists\n", src);
    return 1;
  }
  std::wstring buf(32767, L'\0');
  std::wstring buf2(32767, L'\0');
  auto lpSource = &buf[0];
  auto lpTarget = &buf2[0];
  if (GetFullPathNameW(src, 32767, lpSource, nullptr) == 0) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"GetFullPathNameW: %s\n", err.message());
    return 1;
  }
  if (GetFullPathNameW(target, 32767, lpTarget, nullptr) == 0) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"GetFullPathNameW: %s\n", err.message());
    return 1;
  }
  if (CreateSymbolicLinkW(lpTarget, lpSource, dwflags) != TRUE) {
    ErrorMessage err(GetLastError());
    fwprintf(stderr, L"create symlink error: %s\n", err.message());
    return 1;
  }
  wprintf(L"symlink: %s to %s success.\n", lpSource, lpTarget);
  return 0;
}