////////
#ifndef CLANGBUILDER_VSINSTANCE_HPP
#define CLANGBUILDER_VSINSTANCE_HPP
#include <string>
#include <string_view>

namespace clangbuilder {
struct VSInstance {
  std::wstring InstanceId;
  std::wstring DisplayName;
  std::wstring VSInstallLocation;
  std::wstring Version;
  std::wstring VCToolsetVersion;
  uint64_t ullVersion = 0;
  uint64_t ullMainVersion = 0;
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

} // namespace clangbuilder

#endif