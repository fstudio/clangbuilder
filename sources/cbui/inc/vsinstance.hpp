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
  ULONGLONG ullMainVersion = 0;
  bool IsWin10SDKInstalled = false;
  bool IsWin81SDKInstalled = false;
  bool IsEnterpriseWDK = false;
  bool IsPrerelease = false;
  // Newest version compare, so >
  bool operator<(const VSInstance &r) {
    if (ullMainVersion == r.ullMainVersion) {
      // MainVersion equal
      if (IsPrerelease == r.IsPrerelease) {
        return ullVersion < r.ullVersion;
      }
      return IsPrerelease;
    }
    return ullMainVersion < r.ullMainVersion;
  }
};

} // namespace vssetup

#endif