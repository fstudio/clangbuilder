//////////////
#include "stdafx.h"
#include <stdio.h>
#include <shellapi.h>
#include <Shlwapi.h>
#include <PathCch.h>
#include <strsafe.h>
#include <sstream>
#include <unordered_map>
#include "Clangbuilder.h"
#include "cmVSSetupHelper.h"

bool PutEnvironmentVariableW(const wchar_t *name, const wchar_t *va) {
  std::wstring buf(PATHCCH_MAX_CCH, L'\0');
  auto buffer = &buf[0];
  auto dwSize = GetEnvironmentVariableW(name, buffer, PATHCCH_MAX_CCH);
  if (dwSize <= 0) {
    return SetEnvironmentVariableW(name, va) ? true : false;
  }
  if (dwSize >= PATHCCH_MAX_CCH)
    return false;
  if (buffer[dwSize - 1] != ';') {
    buffer[dwSize] = ';';
    dwSize++;
    buffer[dwSize] = 0;
  }
  StringCchCatW(buffer, PATHCCH_MAX_CCH - dwSize, va);
  return SetEnvironmentVariableW(name, buffer) ? true : false;
}

/// HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\SxS\VS7 11.0
/// 12.0 14.0

#if defined(_M_X64)
#define VSREG_KEY L"SOFTWARE\\WOW6432Node\\Microsoft\\VisualStudio\\SxS\\VS7"
#else
#define VSREG_KEY L"SOFTWARE\\Microsoft\\VisualStudio\\SxS\\VS7"
#endif

bool VisualStudioExists(const std::wstring &id) {
  HKEY hInst = nullptr;
  if (RegOpenKeyExW(HKEY_LOCAL_MACHINE, VSREG_KEY, 0, KEY_READ, &hInst) !=
      ERROR_SUCCESS) {
    /// Not Found Key
    return false;
  }
  DWORD type = REG_SZ;
  WCHAR buffer[4096];
  DWORD dwSize = sizeof(buffer);
  if (RegGetValueW(hInst, nullptr, id.data(), RRF_RT_REG_SZ, &type, buffer,
                   &dwSize) != ERROR_SUCCESS) {
    RegCloseKey(hInst);
    return false;
  }
  RegCloseKey(hInst);
  return true;
}

bool VisualStudioSearch(std::vector<VisualStudioInstance> &instances) {
  instances.clear();
  std::vector<VisualStudioInstance> vss = {
      {L"Visual Studio 2010", L"10.0", L"Visual Studio.10.0"},
      {L"Visual Studio 2012", L"11.0", L"VisualStudio.11.0"},
      {L"Visual Studio 2013", L"12.0", L"VisualStudio.12.0"},
      {L"Visual Studio 2015", L"14.0", L"VisualStudio.14.0"}};
  for (auto &vs : vss) {
    if (VisualStudioExists(vs.installversion)) {
      instances.emplace_back(vs);
    }
  }
  cmVSSetupAPIHelper helper;
  std::vector<VSInstanceInfo> vsInstances;
  if (helper.GetVSInstanceInfo(vsInstances)) {
    for (auto &vs : vsInstances) {
      instances.emplace_back(vs.DisplayName, vs.Version, vs.InstanceId);
    }
  }
  return true;
}
