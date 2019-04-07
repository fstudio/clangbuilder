//////////////

#include "stdafx.h"
#include <stdio.h>
#include <shellapi.h>
#include <Shlwapi.h>
#include <PathCch.h>
#include <strsafe.h>
#include <sstream>
#include <fstream>
#include <unordered_map>
#include "Clangbuilder.h"
#include "cmVSSetupHelper.h"
#include "inc/json.hpp"

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

std::wstring utf8towide(const char *str, DWORD len) {
  std::wstring wstr;
  auto N = MultiByteToWideChar(CP_UTF8, 0, str, len, nullptr, 0);
  if (N > 0) {
    wstr.resize(N);
    MultiByteToWideChar(CP_UTF8, 0, str, len, &wstr[0], N);
  }
  return wstr;
}

bool VisualCppToolsSearch(const std::wstring &cbroot, std::wstring &version) {
  try {
    std::wstring file = cbroot + L"\\bin\\utils\\msvc\\VisualCppTools.lock.json";
    std::ifstream fs;
    fs.open(file, std::ios::binary);
    auto j = nlohmann::json::parse(fs);
    auto name = j["Name"].get<std::string>();
    auto u8ver = j["Version"].get<std::string>();
    version = L"VisualCppTools.Community.Daily ";
    if (name.find("VS2017Layout") == std::string::npos) {
      version = L"VisualCppTools.Community.Daily (VS14Layout) ";
    }
    version += utf8towide(u8ver.c_str(), (DWORD)u8ver.size());
  } catch (const std::exception &e) {
    fprintf(stderr, "%s\n", e.what());
    return false;
  }
  return true;
}

bool EnterpriseWDKSensor(const std::wstring &cbroot,
                         VisualStudioInstance &inst) {
  try {
    std::wstring file = cbroot + L"\\config\\ewdk.json";
    if (!PathFileExistsW(file.c_str())) {
      file = cbroot + L"\\config\\ewdk.template.json";
    }
    std::ifstream fs;
    fs.open(file, std::ios::binary);
    auto j = nlohmann::json::parse(fs);
    auto path = j["Path"].get<std::string>();
    auto version = j["Version"].get<std::string>();
    auto wpath = utf8towide(path.c_str(), (DWORD)path.size());
    if (!PathFileExistsW(wpath.c_str())) {
      return false;
    }
    auto wversion = utf8towide(version.c_str(), (DWORD)version.size());
    inst.description.assign(L"Enterprise WDK ").append(wversion);
    inst.installversion.assign(L"15.0");
    inst.instanceId.assign(L"VisualStudio.EWDK");
  } catch (const std::exception &e) {
    fprintf(stderr, "%s\n", e.what());
    return false;
  }
  return true;
}

bool VisualStudioSearch(const std::wstring &cbroot,
                        std::vector<VisualStudioInstance> &instances) {
  // instances.clear();
  std::vector<VisualStudioInstance> vss = {
      {L"Visual Studio 2010", L"10.0", L"VisualStudio.10.0"},
      {L"Visual Studio 2012", L"11.0", L"VisualStudio.11.0"},
      {L"Visual Studio 2013", L"12.0", L"VisualStudio.12.0"},
      {L"Visual Studio 2015", L"14.0", L"VisualStudio.14.0"}
      /// legacy VisualStudio
  };
  for (auto &vs : vss) {
    if (VisualStudioExists(vs.installversion)) {
      instances.emplace_back(vs);
    }
  }
  VisualStudioInstance inst;
  if (EnterpriseWDKSensor(cbroot, inst)) {
    instances.push_back(std::move(inst));
  }
  std::wstring version;
  if (VisualCppToolsSearch(cbroot, version)) {
    VisualStudioInstance vs;
    vs.description.assign(version);
    vs.instanceId.assign(L"VisualCppTools");
    vs.installversion.assign(L"15.0");
    instances.push_back(std::move(vs));
  }
  cmVSSetupAPIHelper helper;
  std::list<VSInstanceInfo> vsInstances;
  if (helper.GetVSInstanceInfo(vsInstances)) {
    for (auto &vs : vsInstances) {
      instances.emplace_back(vs.DisplayName, vs.Version, vs.InstanceId);
    }
  }
  return true;
}
