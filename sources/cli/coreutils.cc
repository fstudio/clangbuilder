// My coreutils impl
// ln command create link
// pedump dump PE info
// wget
#include "../cbui/inc/base.hpp"
#include <cstdio>
#include <cstdlib>

// make symbolic link.
int ln_main(int argc, wchar_t **argv) {
  //
  return 0;
}

int dumppe_main(int argc, wchar_t **argv) {
  //
  return 0;
}

int dl_main(int argc, wchar_t **argv) {
  //
  return 0;
}

struct subcommand {
  const wchar_t *command;
  int (*entry)(int, wchar_t **);
};

int wmain(int argc, wchar_t **argv) {
  //
  subcommand scmds[] = {
      // sub command
      {L"ln", ln_main},         //
      {L"dumppe", dumppe_main}, //
      {L"dl", dl_main}          //
  };
  if (argc < 2) {
    return 0;
  }
  for (auto s : scmds) {
    if (wcscmp(s.command, argv[1]) == 0) {
      return s.entry(argc--, argv++);
    }
  }
  return 0;
}