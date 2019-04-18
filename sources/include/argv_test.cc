////
#include "argv.hpp"
#include <clocale>
#include <cstdio>
#include <cstdlib>

int wmain(int argc, wchar_t **argv) {
  _wsetlocale(LC_ALL, L"");
  av::ParseArgv pa(argc, argv);
  pa.Add(L"help", av::no_argument, 'h')
      .Add(L"version", av::no_argument, 'v')
      .Add(L"url", av::required_argument, 'u');

  av::error_code ec;
  auto result = pa.Execute(
      [&](int val, const wchar_t *oa, const wchar_t *) {
        switch (val) {
        case 'h':
          wprintf(L"--help\n");
          exit(0);
          break;
        case 'v':
          wprintf(L"--version =1.0\n");
          exit(0);
          break;
        case 'u':
          wprintf(L"url: %s\n", oa);
          break;
        default:
          break;
        }
        return true;
      },
      ec);
  if (!result) {
    wprintf(L"ParseArgv: %s\n", ec.message.data());
    exit(1);
  }
  for (auto p : pa.UnresolvedArgs()) {
    wprintf(L"Unresolve Arg: %s\n", p.data());
  }
  return 0;
}