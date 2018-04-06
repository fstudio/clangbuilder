////
#include <string>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cassert>
#include <ctype.h>

static int hextobin(unsigned char c) {
  switch (c) {
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

bool Flushline(const char *cstr) {
  std::string buf;
  assert(cstr);
  auto len = strlen(cstr);
  buf.reserve(len + 1);
  /// Do Parse....
  auto iter = cstr;
  unsigned char c;
  while ((c = *iter++)) {
    if (c == '\\' && *iter) {
      switch (c = *iter++) {
      case 'a':
        c = '\a';
        break;
      case 'b':
        c = '\b';
        break;
      case 'c':
        return true;
      case 'e':
        c = 0x1B;
		//c=27;
        break;
      case 'f':
        c = '\f';
        break;
      case 'n':
        c = '\n';
        break;
      case 'r':
        c = '\r';
        break;
      case 't':
        c = '\t';
        break;
      case 'v':
        c = '\v';
        break;
      case 'x': {
        unsigned char ch = *iter;
        if (!isxdigit(ch)) {
          buf.push_back(ch);
          continue;
        }
        iter++;
        c = hextobin(ch);
        ch = *iter;
        if (isxdigit(ch)) {
          iter++;
          c = c * 16 + hextobin(ch);
        }
      } break;
      case '0':
        c = 0;
        if (!('0' <= *iter && *iter <= '7'))
          break;
        c = *iter++;
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
        c -= '0';
        if ('0' <= *iter && *iter <= '7')
          c = c * 8 + (*iter++ - '0');
        if ('0' <= *iter && *iter <= '7')
          c = c * 8 + (*iter++ - '0');
      case '\\':
        break;
      default:
        buf.push_back('\\');
        break;
      }
    }
    buf.push_back(c);
  }
  buf.push_back('\n');
  fwrite(buf.c_str(), 1, buf.size(), stderr);
  return true;
}

int main(int argc, char **argv) {
  for (auto i = 1; i < argc; i++) {
    Flushline(argv[i]);
  }
  return 0;
}
