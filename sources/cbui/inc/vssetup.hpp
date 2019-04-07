///////
#ifndef CBUI_VSSETUP_HPP
#define CBUI_VSSETUP_HPP

#include <objbase.h>

// Published by Visual Studio Setup team
// Microsoft.VisualStudio.Setup.Configuration.Native
#include "Setup.Configuration.h"
#include "comutils.hpp"
#include "systemtools.hpp"
#include <vector>

namespace vssetup {
struct VSInstanceItem {
  std::wstring InstanceId;
  std::wstring VSInstallLocation;
  std::wstring Version;
  std::wstring VCToolsetVersion;
  ULONGLONG ullVersion = 0;
  bool IsWin10SDKInstalled = false;
  bool IsWin81SDKInstalled = false;
  bool IsEnterpriseWDK = false;
  bool operator<(const VSInstanceItem &o) { return ullVersion > o.ullVersion; }
};

inline bool operator<(const VSInstanceItem &o, const VSInstanceItem &r) {
  return o.ullVersion > r.ullVersion;
}

class VisualStudioNativeSearcher {
public:
  VisualStudioNativeSearcher()
      : setupConfig(nullptr), setupConfig2(nullptr), setupHelper(nullptr) {
    Initialize();
  }
  VisualStudioNativeSearcher(const VisualStudioNativeSearcher &) = delete;
  VisualStudioNativeSearcher &
  operator=(const VisualStudioNativeSearcher &) = delete;
  bool GetVSInstanceAll(std::vector<VSInstanceItem> &instances);

private:
  bool Initialize();
  bool IsEWDKEnabled();
  priv::comptr<ISetupConfiguration> setupConfig;
  priv::comptr<ISetupConfiguration2> setupConfig2;
  priv::comptr<ISetupHelper> setupHelper;
  bool initializationFailure{false};
};

// TODO initialize
inline bool VisualStudioNativeSearcher::Initialize() {
  if (FAILED(setupConfig.CoCreateInstance(CLSID_SetupConfiguration, NULL,
                                          IID_ISetupConfiguration,
                                          CLSCTX_INPROC_SERVER)) ||
      setupConfig == NULL) {
    initializationFailure = true;
    return false;
  }

  if (FAILED(setupConfig.QueryInterface(IID_ISetupConfiguration2,
                                        (void **)&setupConfig2)) ||
      setupConfig2 == NULL) {
    initializationFailure = true;
    return false;
  }

  if (FAILED(setupConfig.QueryInterface(IID_ISetupHelper,
                                        (void **)&setupHelper)) ||
      setupHelper == NULL) {
    initializationFailure = true;
    return false;
  }

  initializationFailure = false;
  return true;
}

inline bool VisualStudioNativeSearcher::IsEWDKEnabled() {
  std::wstring envEnterpriseWDK, envDisableRegistryUse;
  clangbuilder::GetEnv(L"EnterpriseWDK", envEnterpriseWDK);
  clangbuilder::GetEnv(L"DisableRegistryUse", envDisableRegistryUse);
  return (clangbuilder::UnCaseEqual(envEnterpriseWDK, L"True") &&
          clangbuilder::UnCaseEqual(envDisableRegistryUse, L"True"));
}

inline bool VisualStudioNativeSearcher::GetVSInstanceAll(
    std::vector<VSInstanceItem> &instances) {
  if (initializationFailure) {
    return false;
  }
  if (IsEWDKEnabled()) {
    //
  }
  return true;
}

} // namespace vssetup

#endif