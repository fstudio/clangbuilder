//
#include <bela/stdwriter.hpp>
#include "../baulk/regutils.hpp"
#include <bela/match.hpp>
#include <filesystem>

bool SDKSearchVersion(std::wstring_view sdkroot, std::wstring_view sdkver,
                      std::wstring &sdkversion) {
  auto dir = bela::StringCat(sdkroot, L"\\Include");
  for (auto &p : std::filesystem::directory_iterator(dir)) {
    bela::FPrintF(stderr, L"Lookup: %s\n", p.path().wstring());
    auto filename = p.path().filename().wstring();
    if (bela::StartsWith(filename, sdkver)) {
      sdkversion = filename;
      return true;
    }
  }
  return false;
}

int wmain(int argc, wchar_t **argv) {
  //
  bela::error_code ec;
  auto winsdk = baulk::regutils::LookupWindowsSDK(ec);
  if (!winsdk) {
    bela::FPrintF(stderr, L"unable to find windows sdk %s\n", ec.message);
    return 1;
  }
  std::wstring sdkversion;
  if (!SDKSearchVersion(winsdk->InstallationFolder, winsdk->ProductVersion,
                        sdkversion)) {
    bela::FPrintF(stderr, L"invalid sdk version");
    return 1;
  }
  bela::FPrintF(
      stderr,
      L"InstallationFolder: '%s'\nProductVersion: '%s'\nSDKVersion: '%s'\n",
      winsdk->InstallationFolder, winsdk->ProductVersion, sdkversion);
  return 0;
}