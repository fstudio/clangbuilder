#include <bela/parseargv.hpp>
#include "baulk.hpp"
#include "commands.hpp"
#include "version.h"

namespace baulk {
bool IsDebugMode = false;
}

int cmd_uninitialized(const baulk::commands::argv_t &argv) {
  bela::FPrintF(stderr, L"baulk uninitialized command\n");
  return 1;
}

struct baulkcommand_t {
  baulk::commands::argv_t argv;
  decltype(baulk::commands::cmd_install) *cmd{cmd_uninitialized};
  int operator()() const { return this->cmd(this->argv); }
};

struct command_map_t {
  const std::wstring_view name;
  decltype(baulk::commands::cmd_install) *cmd;
};

void Usage() {
  constexpr std::wstring_view usage =
      LR"(baulk - Minimal Package Manager for Windows
Usage: baulk [option] command pkg ...
  -h|--help      Show usage text and quit
  -v|--version   Show version number and quit
  -V|--verbose   Make the operation more talkative
  --https-proxy  Use this proxy. Equivalent to setting the environment variable 'HTTPS_PROXY'

Command:
  list           List all installed packages
  search         Search for available packages, or specify package details
  install        Install one or more packages
  uninstall      Uninstall one or more packages
  update         Update ports metadata
  upgrade        Upgrade all upgradeable packages
)";
  bela::FPrintF(stderr, L"%s\n", usage);
}
void Version() {
  //
  bela::FPrintF(stderr, L"baulk %s\n", BAULK_VERSION_STRING);
}

bool ParseArgv(int argc, wchar_t **argv, baulkcommand_t &cmd) {
  bela::ParseArgv pa(argc, argv);
  pa.Add(L"help", bela::no_argument, 'h')
      .Add(L"version", bela::no_argument, 'v')
      .Add(L"verbose", bela::no_argument, 'V')
      .Add(L"config", bela::required_argument, 'c')
      .Add(L"https-proxy", bela::required_argument, 1001);
  bela::error_code ec;
  auto result = pa.Execute(
      [&](int val, const wchar_t *oa, const wchar_t *) {
        switch (val) {
        case 'h':
          Usage();
          exit(0);
        case 'v':
          Version();
          exit(0);
        case 'V':
          baulk::IsDebugMode = true;
          break;
        case 1001:
          SetEnvironmentVariableW(L"HTTPS_PROXY", oa);
          break;
        default:
          return false;
        }
        return true;
      },
      ec);
  if (!result) {
    bela::FPrintF(stderr, L"baulk ParseArgv error: %s\n", ec.message);
    return false;
  }
  if (pa.UnresolvedArgs().empty()) {
    bela::FPrintF(stderr, L"baulk no command input\n");
    return false;
  }
  auto subcmd = pa.UnresolvedArgs().front();
  cmd.argv.assign(pa.UnresolvedArgs().begin() + 1, pa.UnresolvedArgs().end());
  constexpr command_map_t cmdmaps[] = {
      {L"install", baulk::commands::cmd_install},
      {L"list", baulk::commands::cmd_list},
      {L"search", baulk::commands::cmd_search},
      {L"uninstall", baulk::commands::cmd_uninstall},
      {L"update", baulk::commands::cmd_update},
      {L"upgrade", baulk::commands::cmd_upgrade}};
  for (const auto &c : cmdmaps) {
    if (subcmd == c.name) {
      cmd.cmd = c.cmd;
      return true;
    }
  }
  bela::FPrintF(stderr, L"baulk unsupport command: %s\n", subcmd);
  return false;
}

int wmain(int argc, wchar_t **argv) {
  baulkcommand_t cmd;
  if (!ParseArgv(argc, argv, cmd)) {
    return 1;
  }
  return cmd();
}