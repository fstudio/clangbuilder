///////
#ifndef CBUI_VSSETUP_HPP
#define CBUI_VSSETUP_HPP

#include <objbase.h>

// Published by Visual Studio Setup team
// Microsoft.VisualStudio.Setup.Configuration.Native
#include "Setup.Configuration.h"
#include "base.hpp"
#include "comutils.hpp"
#include "systemtools.hpp"
#include <vector>
#include <fstream>
#include "vsinstance.hpp"

#ifndef VSSetupConstants
#define VSSetupConstants
/* clang-format off */
const IID IID_ISetupConfiguration = {
  0x42843719, 0xDB4C, 0x46C2,
  { 0x8E, 0x7C, 0x64, 0xF1, 0x81, 0x6E, 0xFD, 0x5B }
};
const IID IID_ISetupConfiguration2 = {
  0x26AAB78C, 0x4A60, 0x49D6,
  { 0xAF, 0x3B, 0x3C, 0x35, 0xBC, 0x93, 0x36, 0x5D }
};
const IID IID_ISetupPackageReference = {
  0xda8d8a16, 0xb2b6, 0x4487,
  { 0xa2, 0xf1, 0x59, 0x4c, 0xcc, 0xcd, 0x6b, 0xf5 }
};
const IID IID_ISetupHelper = {
  0x42b21b78, 0x6192, 0x463e,
  { 0x87, 0xbf, 0xd5, 0x77, 0x83, 0x8f, 0x1d, 0x5c }
};
const IID IID_IEnumSetupInstances = {
  0x6380BCFF, 0x41D3, 0x4B2E,
  { 0x8B, 0x2E, 0xBF, 0x8A, 0x68, 0x10, 0xC8, 0x48 }
};
const IID IID_ISetupInstance2 = {
  0x89143C9A, 0x05AF, 0x49B0,
  { 0xB7, 0x17, 0x72, 0xE2, 0x18, 0xA2, 0x18, 0x5C }
};
const IID IID_ISetupInstance = {
  0xB41463C3, 0x8866, 0x43B5,
  { 0xBC, 0x33, 0x2B, 0x06, 0x76, 0xF7, 0xF4, 0x2E }
};
const CLSID CLSID_SetupConfiguration = {
  0x177F0C4A, 0x1CD3, 0x4DE7,
  { 0xA3, 0x2C, 0x71, 0xDB, 0xBB, 0x9F, 0xA3, 0x6D }
};
/* clang-format on */
#endif

namespace vssetup {

class VisualStudioNativeSearcher {
public:
  VisualStudioNativeSearcher()
      : setupConfig(nullptr), setupConfig2(nullptr), setupHelper(nullptr) {
    Initialize();
  }
  VisualStudioNativeSearcher(const VisualStudioNativeSearcher &) = delete;
  VisualStudioNativeSearcher &
  operator=(const VisualStudioNativeSearcher &) = delete;
  bool GetVSInstanceAll(std::vector<VSInstance> &instances);

private:
  bool Initialize();
  bool IsEWDKEnabled();
  bool GetVSInstanceInfo(priv::comptr<ISetupInstance2> inst, VSInstance &vsi);
  bool CheckInstalledComponent(priv::comptr<ISetupPackageReference> package,
                               bool &bWin10SDK, bool &bWin81SDK);
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

inline std::wstring LookupVCToolsetVersion(std::wstring_view vsdir) {
  auto vcfile = base::strcat(
      vsdir, L"/VC/Auxiliary/Build/Microsoft.VCToolsVersion.default.txt");
  std::ifstream fin(vcfile);
  if (!fin) {
    return L"";
  }
  std::string line; /// is utf8
  std::getline(fin, line);
  if (line.empty()) {
    return L"";
  }
  auto sv = clangbuilder::StripAsciiWhitespace(line);
  return clangbuilder::utf8towide(sv);
}

inline bool VisualStudioNativeSearcher::CheckInstalledComponent(
    priv::comptr<ISetupPackageReference> package, bool &bWin10SDK,
    bool &bWin81SDK) {
  constexpr const WCHAR *Win10SDKComponent =
      L"Microsoft.VisualStudio.Component.Windows10SDK";
  constexpr const WCHAR *Win81SDKComponent =
      L"Microsoft.VisualStudio.Component.Windows81SDK";
  constexpr const WCHAR *ComponentType = L"Component";
  bool ret = false;
  bWin10SDK = bWin81SDK = false;
  priv::comstr bstrId;
  if (FAILED(package->GetId(&bstrId))) {
    return ret;
  }

  priv::comstr bstrType;
  if (FAILED(package->GetType(&bstrType))) {
    return ret;
  }

  std::wstring id = std::wstring(bstrId);
  std::wstring type = std::wstring(bstrType);

  // Checks for any version of Win10 SDK. The version is appended at the end of
  // the
  // component name ex: Microsoft.VisualStudio.Component.Windows10SDK.10240
  if (id.find(Win10SDKComponent) != std::wstring::npos &&
      type.compare(ComponentType) == 0) {
    bWin10SDK = true;
    ret = true;
  }

  if (id.compare(Win81SDKComponent) == 0 && type.compare(ComponentType) == 0) {
    bWin81SDK = true;
    ret = true;
  }

  return ret;
}

inline bool VisualStudioNativeSearcher::GetVSInstanceInfo(
    priv::comptr<ISetupInstance2> inst, VSInstance &vsi) {
  if (inst == nullptr) {
    return false;
  }

  priv::comstr bstrId;
  if (FAILED(inst->GetInstanceId(&bstrId))) {
    return false;
  }
  vsi.InstanceId = std::wstring(bstrId);
  InstanceState state;
  if (FAILED(inst->GetState(&state))) {
    return false;
  }
  auto lcid = GetUserDefaultLCID();
  priv::comstr bstrName;
  if (SUCCEEDED(inst->GetDisplayName(lcid, &bstrName))) {
    vsi.DisplayName = std::wstring(bstrName);
  }
  priv::comptr<ISetupInstanceCatalog> catalog;
  if (SUCCEEDED(inst->QueryInterface(__uuidof(ISetupInstanceCatalog),
                                     (void **)&catalog)) &&
      catalog != nullptr) {
    variant_t vt;
    if (SUCCEEDED(catalog->IsPrerelease(&vt.boolVal))) {
      vsi.IsPrerelease = (vt.boolVal != VARIANT_FALSE);
    }
  }
  vsi.DisplayName.append(vsi.IsPrerelease ? L" (Preview)" : L" (Release)");
  ULONGLONG ullVersion = 0;
  priv::comstr bstrVersion;
  if (FAILED(inst->GetInstallationVersion(&bstrVersion))) {
    return false;
  }
  vsi.Version = std::wstring(bstrVersion);
  if (SUCCEEDED(setupHelper->ParseVersion(bstrVersion, &ullVersion))) {
    vsi.ullVersion = ullVersion;
  }

  // Reboot may have been required before the installation path was created.
  priv::comstr bstrInstallationPath;
  if ((eLocal & state) == eLocal) {
    if (FAILED(inst->GetInstallationPath(&bstrInstallationPath))) {
      return false;
    }
    vsi.VSInstallLocation = std::wstring(bstrInstallationPath);
  }
  vsi.VCToolsetVersion = LookupVCToolsetVersion(vsi.VSInstallLocation);
  // Reboot may have been required before the product package was registered
  // (last).
  if ((eRegistered & state) == eRegistered) {
    priv::comptr<ISetupPackageReference> product;
    if (FAILED(inst->GetProduct(&product)) || !product) {
      return false;
    }

    LPSAFEARRAY lpsaPackages;
    if (FAILED(inst->GetPackages(&lpsaPackages)) || lpsaPackages == NULL) {
      return false;
    }

    int lower = lpsaPackages->rgsabound[0].lLbound;
    int upper = lpsaPackages->rgsabound[0].cElements + lower;

    IUnknown **ppData = (IUnknown **)lpsaPackages->pvData;
    for (int i = lower; i < upper; i++) {
      priv::comptr<ISetupPackageReference> package = NULL;
      if (FAILED(ppData[i]->QueryInterface(IID_ISetupPackageReference,
                                           (void **)&package)) ||
          package == nullptr) {
        continue;
      }

      bool win10SDKInstalled = false;
      bool win81SDkInstalled = false;
      bool ret = CheckInstalledComponent(package, win10SDKInstalled,
                                         win81SDkInstalled);
      if (ret) {
        vsi.IsWin10SDKInstalled |= win10SDKInstalled;
        vsi.IsWin81SDKInstalled |= win81SDkInstalled;
      }
    }
    SafeArrayDestroy(lpsaPackages);
  }
  return true;
}

inline bool VisualStudioNativeSearcher::GetVSInstanceAll(
    std::vector<VSInstance> &instances) {
  if (initializationFailure) {
    return false;
  }
  if (IsEWDKEnabled()) {
    std::wstring envWindowsSdkDir81, envVSVersion, envVsInstallDir;
    clangbuilder::GetEnvString(L"WindowsSdkDir_81", envWindowsSdkDir81);
    clangbuilder::GetEnvString(L"VisualStudioVersion", envVSVersion);
    clangbuilder::GetEnvString(L"VSINSTALLDIR", envVsInstallDir);
    if (!envVSVersion.empty() && !envVsInstallDir.empty()) {
      // TODO allowed version
      VSInstance item;
      item.IsEnterpriseWDK = true;
      item.VSInstallLocation = envVsInstallDir;
      item.Version = envVSVersion;
      item.DisplayName =
          base::strcat(L"Visual Studio ", envVSVersion, L" (EnterpriseWDK)");
      item.VCToolsetVersion = LookupVCToolsetVersion(item.VSInstallLocation);
      item.ullVersion = std::stoi(envVSVersion);
      item.IsWin10SDKInstalled = true;
      item.IsWin81SDKInstalled = !envWindowsSdkDir81.empty();
      instances.push_back(std::move(item));
    }
  }
  // resolve all instances.
  priv::comptr<IEnumSetupInstances> es;
  if (FAILED(setupConfig2->EnumInstances((IEnumSetupInstances **)&es))) {
    return false;
  }
  priv::comptr<ISetupInstance> instance;
  while (SUCCEEDED(es->Next(1, &instance, nullptr)) && instance) {
    priv::comptr<ISetupInstance2> instance2 = nullptr;
    if (FAILED(instance->QueryInterface(IID_ISetupInstance2,
                                        (void **)&instance2)) ||
        instance2 == nullptr) {
      instance = nullptr;
      continue;
    }
    VSInstance item;
    if (GetVSInstanceInfo(instance2, item)) {
      instances.push_back(std::move(item));
    }
    instance = nullptr;
    ///////// query once
  }
  std::sort(instances.begin(), instances.end());
  return true;
}

} // namespace vssetup

#endif