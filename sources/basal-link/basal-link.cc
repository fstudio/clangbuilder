#include <cstdio>
#include <cstdlib>
#include <clocale>
#include <Windows.h>

#ifndef SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE
#define SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE 0x02
#endif


int wmain(int argc, wchar_t **argv) {
  setlocale(LC_ALL, ""); //// Codepage no way
  if (argc < 3) {
    fwprintf(stderr, L"usage: basal-link source target\n");
    return 1;
  }
  if (CreateSymbolicLinkW(argv[2], argv[1],
                          SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE)) {
    wprintf(L"create symbolic link file: %s success.\n", argv[2]);
    return 0;
  }
  LPWSTR message = nullptr;
  if (FormatMessageW(
          FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER, nullptr,
          GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL),
          (LPWSTR)&message, 0, nullptr) == 0) {
    fwprintf(stderr, L"unkown error\n");
    return 1;
  }
  fwprintf(stderr, L"basal-link error: %s\n", message);
  LocalFree(message);
  return 1;
}
