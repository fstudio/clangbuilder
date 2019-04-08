////////
#ifndef VSINSTANCE_HPP
#define VSINSTANCE_HPP
#include <string>
#include <string_view>
#include <Windows.h>

namespace vssetup {
struct VSInstance {
  std::wstring InstanceId;
  std::wstring DisplayName;
  std::wstring VSInstallLocation;
  std::wstring Version;
  std::wstring VCToolsetVersion;
  ULONGLONG ullVersion = 0;
  bool IsWin10SDKInstalled = false;
  bool IsWin81SDKInstalled = false;
  bool IsEnterpriseWDK = false;
  bool IsPrerelease = false;
  bool operator<(const VSInstance &o) { return ullVersion < o.ullVersion; }
};

inline bool operator<(const VSInstance &o, const VSInstance &r) {
  return o.ullVersion < r.ullVersion;
}

} // namespace vssetup

#endif