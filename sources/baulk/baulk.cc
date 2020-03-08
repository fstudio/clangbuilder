#include <bela/parseargv.hpp>
#include "baulk.hpp"
#include "commands.hpp"

namespace baulk {
bool IsDebugMode = false;
}

// baulk command package manager for C++
// install
// search
// uninstall

struct baulkcommand_t {
  baulk::commands::argv_t argv;
  decltype(baulk::commands::cmd_install) *cmd;
  int operator()() const { return this->cmd(this->argv); }
};

struct command_map_t {
  const std::wstring_view name;
  decltype(baulk::commands::cmd_install) *cmd;
};

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
          break;
        case 'v':
          break;
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