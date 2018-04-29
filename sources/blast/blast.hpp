/////////////////////

#ifndef BLAST_HPP
#define BLAST_HPP
#define WIN32_LEAN_AND_MEAN
#include <Objbase.h>
#include <Shellapi.h>
#include <Windows.h>
#include <string>
#include <winioctl.h>
#include <winnt.h>

class ErrorMessage {
public:
  ErrorMessage(DWORD errid) : lastError(errid) {
    if (FormatMessageW(
            FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER,
            nullptr, errid, MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL),
            (LPWSTR)&buf, 0, nullptr) == 0) {
      buf = nullptr;
    }
  }
  ~ErrorMessage() {
    if (buf != nullptr) {
      LocalFree(buf);
    }
  }
  const wchar_t *message() const { return buf == nullptr ? L"unknwon" : buf; }
  DWORD LastError() const { return lastError; }

private:
  DWORD lastError;
  LPWSTR buf{nullptr};
};

int readlinkall(int fn, wchar_t **files);
int symlink(const wchar_t *src, const wchar_t *target);
int dumpbin(const std::wstring &path);

class Arguments {
public:
  Arguments() : argv_(4096, L'\0') {}
  Arguments &assign(const wchar_t *app) {
    std::wstring realcmd(0x8000, L'\0');
    //// N include terminating null character
    auto N = ExpandEnvironmentStringsW(app, &realcmd[0], 0x8000);
    realcmd.resize(N - 1);
    std::wstring buf;
    bool needwarp = false;
    for (auto c : realcmd) {
      switch (c) {
      case L'"':
        buf.push_back(L'\\');
        buf.push_back(L'"');
        break;
      case L'\t':
        needwarp = true;
        break;
      case L' ':
        needwarp = true;
      default:
        buf.push_back(c);
        break;
      }
    }
    if (needwarp) {
      argv_.assign(L"\"").append(buf).push_back(L'"');
    } else {
      argv_.assign(std::move(buf));
    }
    return *this;
  }
  Arguments &append(const wchar_t *cmd) {
    std::wstring buf;
    bool needwarp = false;
    auto end = cmd + wcslen(cmd);
    for (auto iter = cmd; iter != end; iter++) {
      switch (*iter) {
      case L'"':
        buf.push_back(L'\\');
        buf.push_back(L'"');
        break;
      case L' ':
      case L'\t':
        needwarp = true;
      default:
        buf.push_back(*iter);
        break;
      }
    }
    if (needwarp) {
      argv_.append(L" \"").append(buf).push_back(L'"');
    } else {
      argv_.append(L" ").append(buf);
    }
    return *this;
  }
  const std::wstring &str() { return argv_; }

private:
  std::wstring argv_;
};

#endif