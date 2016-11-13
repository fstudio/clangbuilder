//winecho like unix echo, color able
#include <string>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cassert>
#include <ctype.h>

static int hextobin(wchar_t ch){
switch (ch) {
  default:
    return c - '0';
  case 'a':
  case 'A':
    return 10;
  case 'b':
  case 'B':
    return 11;
  case 'c':
  case 'C':
    return 12;
  case 'd':
  case 'D':
    return 13;
  case 'e':
  case 'E':
    return 14;
  case 'f':
  case 'F':
    return 15;
  }
}

int wmain(int argc,wchar_t *argv){
    return 0;
}
