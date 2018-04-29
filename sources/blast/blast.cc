#include "blast.hpp"



void usage() {
  const wchar_t *kusage = LR"(blast symbolic linker
    --readlink     read symbolic link file's source 
    --link         create a symlink
    --dump         dump exe subsystem and machine info
    --help         print usage and exit.
example:
    blast --link source target
    blast --readlink file1 file2 fileN
    blast --dump exefile)";
  wprintf(L"%s\n", kusage);
}

/// blast --link source target
/// blast --readlink source
class DotComInitialize {
public:
  DotComInitialize() {
    if (FAILED(CoInitialize(NULL))) {
      throw std::runtime_error("CoInitialize failed");
    }
  }
  ~DotComInitialize() { CoUninitialize(); }
};

int wmain(int argc, wchar_t **argv) {
  DotComInitialize dot;
  setlocale(LC_ALL, ""); //
  if (argc >= 2 && wcscmp(argv[1], L"--help") == 0) {
    usage();
    return 0;
  }
  if (argc < 3) {
    wprintf(L"usage: %s <options> file\n", argv[0]);
    return 1;
  }
  if (wcscmp(argv[1], L"--readlink") == 0) {
    return readlinkall(argc - 2, argv + 2);
  }
  if (wcscmp(argv[1], L"--link") == 0 && argc >= 4) {
    return symlink(argv[2], argv[3]);
  }
  if (wcscmp(argv[1], L"--dump") == 0 && argc >= 3) {
    return dumpbin(argv[2]);
  }
  fwprintf(stderr, L"unsupport option: '%s'\n", argv[1]);
  return 1;
}