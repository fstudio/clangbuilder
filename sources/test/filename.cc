#include <iostream>
#include <Windows.h>

int wmain() {
  WCHAR buffer[8192];
  setlocale(LC_ALL, ""); //// Codepage no way
  if (GetModuleFileNameW(nullptr, buffer, 8192)) {
    wprintf(L"File: %s.\n", buffer);
  } else {
    wprintf(L"failed");
  }
  return 1;
}