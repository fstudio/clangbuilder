/////////
#include "../include/appfs.hpp"
#include "../include/parseargv.hpp"
#include "../res/version.h"
#include "pe.hpp"
#include "resolve.hpp"
#include <clocale>
#include <objbase.h>

class dot_global_initializer {
public:
  dot_global_initializer() {
    if (FAILED(::CoInitialize(nullptr))) {
      ::MessageBoxW(nullptr, L"CoInitialize() failed", L"COM initialize failed",
                    MB_OK | MB_ICONERROR);
      ExitProcess(1);
    }
  }
  dot_global_initializer(const dot_global_initializer &) = delete;
  dot_global_initializer &operator=(const dot_global_initializer &) = delete;
  ~dot_global_initializer() { ::CoUninitialize(); }

private:
};

template <typename V> std::wstring flatvector(const V &v) {
  std::wstring s;
  for (const auto &i : v) {
    s.append(i).append(L", ");
  }
  if (s.size() > 2) {
    s.resize(s.size() - 2);
  }
  return s;
}

int dumpbin(std::wstring_view exe) {
  base::error_code ec;
  auto pe = pecoff::inquisitive_pecoff(exe, ec);
  if (!pe) {
    fwprintf_s(stderr, L"dumpbin: %s\n", ec.data());
    return 1;
  }
  std::wstring buf;
  buf.assign(L"{\n    \"Machine\": \"")
      .append(pe->machine)
      .append(L"\",\n    \"Subsystem\": \"")
      .append(pe->subsystem)
      .append(L"\",\n    \"Characteristics\": \"")
      .append(flatvector(pe->characteristics))
      .append(L"\",\n    \"Depends\": \"")
      .append(flatvector(pe->depends))
      .append(L"\"\n}");
  wprintf_s(L"%s", buf.data());
  return 0;
}

int symlink(std::wstring_view source, std::wstring_view target) {
  std::wstring source_, target_;
  if (!clangbuilder::PathAbsolute(source_, source)) {
    fwprintf_s(stderr, L"Path: %s unreadable\n", source.data());
    return 1;
  }
  if (!clangbuilder::PathAbsolute(target_, target)) {
    fwprintf_s(stderr, L"Path: %s unreadable\n", target.data());
    return 1;
  }
  DWORD dwflags = SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE;
  if (CreateSymbolicLinkW(target_.data(), source_.data(), dwflags) != TRUE) {
    auto ec = base::make_system_error_code();
    fwprintf_s(stderr, L"CreateSymbolicLinkW(): %s\n", ec.data());
    return 1;
  }
  wprintf_s(L"Link %s to %s success\n", source_.data(), target_.data());
  return 0;
}

int readonelink(std::wstring_view file) {
  base::error_code ec;
  auto lr = inquisitive::ResolveTarget(file, ec);
  if (!lr) {
    if (ec) {
      fwprintf_s(stderr, L"File: %s unable resolve target\n", file.data());
      return 1;
    }
    wprintf_s(L"File: %s is hardlink\n", file.data());
    return 0;
  }
  switch (lr->type) {
  case inquisitive::SymbolicLink:
    wprintf_s(L"Symlink: %s --> %s\n", file.data(), lr->path.data());
    break;
  case inquisitive::MountPoint:
    wprintf_s(L"Mount Point: %s --> %s\n", file.data(), lr->path.data());
    break;
  case inquisitive::WimImage: {
    auto al = std::get<inquisitive::reparse_wim_t>(lr->av);
    wprintf_s(L"WimImage: %s\nGUID:     %s\nHash:     %s\n", file.data(),
              al.guid.data(), al.hash.data());
    break;
  }
  case inquisitive::Wof: {
    auto al = std::get<inquisitive::reparse_wof_t>(lr->av);
    wprintf_s(
        L"Wof: %s WofVersion: %ld Provider: %ld Version: %ld Algorithm: %ld\n",
        file.data(), al.wofversion, al.wofprovider, al.version, al.algorithm);
    break;
  }
  case inquisitive::Wcifs: {
    auto al = std::get<inquisitive::reparse_wcifs_t>(lr->av);
    wprintf_s(L"Wcifs: %s Version: %ld Reserved: %ld\nGUID: %s\nWciName: %s\n",
              file.data(), al.Version, al.Reserved, al.LookupGuid.data(),
              al.WciName.data());
    break;
  }
  case inquisitive::AppExecLink: {
    auto al = std::get<inquisitive::appexeclink_t>(lr->av);
    wprintf_s(L"File: %s is a AppExecLink\nTarget:     %s\nID:         "
              L"%s\nAppUserID:  %s\n",
              file.data(), lr->path.data(), al.pkid.data(),
              al.appuserid.data());
    break;
  }
  case inquisitive::AFUnix:
    wprintf_s(L"Unix domain socket: %s\n", file.data());
    break;
  case inquisitive::OneDrive:
    wprintf_s(L"OneDrive: %s\n", file.data());
    break;
  case inquisitive::Placeholder:
    wprintf_s(L"Placeholder: %s\n", file.data());
    break;
  case inquisitive::StorageSync:
    wprintf_s(L"Storage sync: %s\n", file.data());
    break;
  case inquisitive::ProjFS:
    wprintf_s(L"ProjFS(VFS for Git): %s\n", file.data());
    break;
  default:
    wprintf_s(L"Unknown: %s --> %s\n", file.data(), lr->path.data());
    break;
  }
  return 0;
}

int readlinks(const std::vector<std::wstring_view> &files) {
  for (auto f : files) {
    readonelink(f);
  }
  return 0;
}

enum blast_execute_mode {
  None = 0, //
  SymlinkCreator,
  SymlinkReader,
  PEDumper
};

void usage() {
  const wchar_t *kusage = LR"(blast - clangbuilder symlink utility
    -R|--readlink     read symbolic link file's source 
    -L|--link         create a symlink
    -D|--dump         dump exe subsystem and machine info
    -h|--help         print usage and exit.
    -v|--version      print version and exit

example:
    blast --link source target
    blast --readlink file1 file2 fileN
    blast --dump exefile)";
  wprintf(L"%s\n", kusage);
}

int wmain(int argc, wchar_t **argv) {
  dot_global_initializer di;
  _wsetlocale(LC_ALL, L"");
  blast_execute_mode md = None;

  av::ParseArgv pa(argc, argv);
  pa.Add(L"readlink", av::no_argument, L'R')
      .Add(L"link", av::no_argument, L'L')
      .Add(L"dump", av::no_argument, L'D')
      .Add(L"help", av::no_argument, L'h')
      .Add(L"version", av::no_argument, 'v');
  av::error_code ec;
  auto result = pa.Execute(
      [&](int val, const wchar_t *, const wchar_t *) {
        //
        switch (val) {
        case 'R':
          md = SymlinkReader;
          break;
        case 'L':
          md = SymlinkCreator;
          break;
        case 'D':
          md = PEDumper;
          break;
        case 'h':
          usage();
          exit(0);
          break;
        case 'v':
          wprintf_s(L"blast: %s\n", CLANGBUILDER_VERSION_FULL);
          exit(0);
          break;
        default:
          break;
        }
        return true;
      },
      ec);
  switch (md) {
  case None:
    usage();
    return 1;
  case SymlinkReader: {
    if (pa.UnresolvedArgs().empty()) {
      fwprintf_s(stderr, L"--readlink missing argument\n");
      return 1;
    }
    return readlinks(pa.UnresolvedArgs());
  }
  case SymlinkCreator: {
    if (pa.UnresolvedArgs().size() < 2) {
      fwprintf_s(stderr, L"--link missing argument\n");
      return 1;
    }
    return symlink(pa.UnresolvedArgs()[0], pa.UnresolvedArgs()[1]);
  }
  case PEDumper: {
    if (pa.UnresolvedArgs().empty()) {
      fwprintf_s(stderr, L"--dump missing argument\n");
      return 1;
    }
    return dumpbin(pa.UnresolvedArgs()[0]);
  }
  default:
    break;
  }

  return 0;
}