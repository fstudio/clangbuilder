//
#include <bela/str_join.hpp>
#include <bela/terminal.hpp>

int wmain() {
  constexpr std::wstring_view strs[] = {L"1", L"---", L"XXX", L"ZZZZ", L"NNNN"};
  auto s = bela::StrJoin(strs, L";");
  bela::FPrintF(stderr, L"Joined: %s\n", s);
  return 0;
}