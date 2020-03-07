//
#include <bela/stdwriter.hpp>
#include "../baulk/xml.hpp"

int wmain(int argc, wchar_t **argv) {
  if (argc < 2) {
    bela::FPrintF(stderr, L"usage: %s /path/to/SDKManifest.xml\n", argv[0]);
    return 1;
  }
  std::wstring version;
  bela::error_code ec;
  if (!baulk::xml::ParseSdkVersion(argv[1], version, ec)) {
    bela::FPrintF(stderr, L"unable lookup sdk version\nFile: %s\nError: %s\n",
                  argv[1], ec.message);
    return 1;
  }
  bela::FPrintF(stderr, L"SDK version: %s\n", version);
  return 0;
}