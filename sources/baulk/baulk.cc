#include <bela/parseargv.hpp>
#include "baulk.hpp"

namespace baulk {
bool IsDebugMode = false;
}

// baulk command package manager for C++
// install
// search
// uninstall

bool ParseArgv(int argc, wchar_t **argv) {
  bela::ParseArgv pa(argc, argv, true);
  return false;
}

int wmain(int argc, wchar_t **argv) {
  //
  return 0;
}