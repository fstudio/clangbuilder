/////////
#include <clocale>
#include "../include/parseargv.hpp"

int wmain(int argc, wchar_t **argv) {
  _wsetlocale(LC_ALL, L"");
  return 0;
}