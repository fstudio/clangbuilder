//// New blast
#include <bela/stdwriter.hpp>
#include <bela/repasepoint.hpp>
#include <bela/path.hpp>
#include <bela/parseargv.hpp>
#include <filesystem>
#include <json.hpp>
#include "pe.hpp"
// version
#include "../res/version.h"

void usage() {
  constexpr std::wstring_view kusage = LR"(blast - clangbuilder symlink utility
    -R|--readlink     read symbolic link file's source
    -L|--link         create a symlink
    -D|--dump         dump exe subsystem and machine info
    -A|--analyze      analyze file reparsepoint
    -h|--help         print usage and exit.
    -v|--version      print version and exit
    -F|--force        force mode (--link)
    -J|--json         output format to json

example:
    blast --link source target
    blast --readlink file1 file2 fileN
    blast --dump exefile
)";
  bela::FPrintF(stderr, L"%s\n", kusage);
}

int dumpexejson(bela::PESimpleDetails &pe) {
  try {
    nlohmann::json j;
    j["Machine"] = bela::ToNarrow(
        clangbuilder::Machine(static_cast<uint32_t>(pe.machine)));
    j["Subsystem"] = bela::ToNarrow(
        clangbuilder::Subsystem(static_cast<uint32_t>(pe.subsystem)));
    j["Depends"] = nlohmann::json::array();
    auto &depends = j["Depends"];
    for (const auto &d : pe.depends) {
      // vscode-cpptools BUG !!!
      depends.emplace_back(bela::ToNarrow(d));
    }
    j["Delay"] = nlohmann::json::array();
    auto &delays = j["Delay"];
    for (const auto &d : pe.delays) {
      delays.emplace_back(bela::ToNarrow(d));
    }
    j["DllCharacteristics"] = pe.dllcharacteristics;
    j["Characteristics"] = pe.characteristics;
    bela::FPrintF(stdout, L"%s", j.dump(4)); /// output
  } catch (const std::exception &e) {
    bela::FPrintF(stderr, L"unable parse exe: %s\n", e.what());
    return -1;
  }
  return 0;
}

int dumpexe(std::wstring_view exe, bool tojson) {
  bela::error_code ec;
  auto pe = bela::PESimpleDetailsAze(exe, ec);
  if (!pe) {
    bela::FPrintF(stderr, L"unable parse exe: %s\n", ec.message);
    return -1;
  }
  if (tojson) {
    return dumpexejson(*pe);
  }
  bela::FPrintF(stdout, L"Machine:    %s\n",
                clangbuilder::Machine(static_cast<uint32_t>(pe->machine)));
  bela::FPrintF(stdout, L"Subsystem:  %s\n",
                clangbuilder::Subsystem(static_cast<uint32_t>(pe->subsystem)));
  if (!pe->depends.empty()) {
    bela::FPrintF(stdout, L"Depends:    %s\n", pe->depends[0]);
    for (size_t i = 1; i < pe->depends.size(); i++) {
      bela::FPrintF(stdout, L"            %s\n", pe->depends[i]);
    }
  }
  if (!pe->delays.empty()) {
    bela::FPrintF(stdout, L"Delays:     %s\n", pe->delays[0]);
    for (size_t i = 1; i < pe->delays.size(); i++) {
      bela::FPrintF(stdout, L"            %s\n", pe->delays[i]);
    }
  }
  return 0;
}

bool analyzefile(std::wstring_view src, bool tojson) {
  bela::ReparsePoint rp;
  bela::error_code ec;
  if (!rp.Analyze(src, ec)) {
    bela::FPrintF(stderr, L"unable resolve %s error: %s\n", src, ec.message);
    return false;
  }
  if (tojson) {
    try {
      nlohmann::json j;
      for (const auto &e : rp.Attributes()) {
        j[bela::ToNarrow(e.name)] = bela::ToNarrow(e.value);
      }
      bela::FPrintF(stdout, L"%s", j.dump(4)); /// output
    } catch (const std::exception &e) {
      bela::FPrintF(stderr, L"unable parse exe: %s\n", e.what());
      return false;
    }
    return true;
  }
  constexpr size_t alignsize = 20;
  std::wstring s(alignsize, L' ');
  std::wstring_view sv = s;
  bela::FPrintF(stdout, L"%s:\n", src);
  for (const auto &e : rp.Attributes()) {
    if (e.name.size() >= alignsize) {
      bela::FPrintF(stdout, L"%s: %s\n", e.name, e.value);
      continue;
    }
    bela::FPrintF(stdout, L"%s:%s%s\n", e.name,
                  sv.substr(0, alignsize - e.name.size()), e.value);
  }
  return true;
}

int createsymlink(std::wstring_view src, std::wstring_view dest, bool force) {
  std::error_code ec;
  auto psrc = std::filesystem::canonical(src, ec);
  if (ec) {
    auto sec = bela::make_system_error_code();
    bela::FPrintF(stderr, L"unable convert %s to absolute path error: %s\n",
                  src, sec.message);
    return -1;
  }
  auto pdest = std::filesystem::absolute(dest, ec);
  if (std::filesystem::exists(pdest, ec)) {
    if (!force) {
      bela::FPrintF(stderr, L"symlink %s exists\n", dest);
      return 1;
    }
    std::filesystem::remove(dest, ec);
    if (ec) {
      auto sec = bela::make_system_error_code();
      bela::FPrintF(stderr, L"unable remove %s to absolute path error: %s\n",
                    dest, sec.message);
      return -1;
    }
  }
  std::filesystem::create_symlink(psrc, pdest, ec);
  if (ec) {
    auto sec = bela::make_system_error_code();
    bela::FPrintF(stderr, L"create symlink: from %s to %s error: %s\n",
                  psrc.c_str(), pdest.c_str(), sec.message);
    return -1;
  }
  bela::FPrintF(stdout, L"Link %s to %s success\n", psrc.c_str(),
                pdest.c_str());
  return 0;
}

enum blast_execute_mode {
  None = 0, //
  SymlinkCreator,
  SymlinkReader,
  AnalyzeFile,
  PEDumper
};

int wmain(int argc, wchar_t **argv) {
  blast_execute_mode md = None;
  bool tojson = false;
  bool force = false;
  bela::ParseArgv pa(argc, argv);
  pa.Add(L"readlink", bela::no_argument, L'R')
      .Add(L"link", bela::no_argument, L'L')
      .Add(L"dump", bela::no_argument, L'D')
      .Add(L"help", bela::no_argument, L'h')
      .Add(L"version", bela::no_argument, 'v')
      .Add(L"json", bela::no_argument, 'J')
      .Add(L"force", bela::no_argument, 'F')
      .Add(L"analyze", bela::no_argument, 'A'); //-A|--analyze
  bela::error_code ec;
  auto result = pa.Execute(
      [&](int val, const wchar_t *, const wchar_t *) {
        switch (val) {
        case 'A':
          md = AnalyzeFile;
          break;
        case 'R':
          md = SymlinkReader;
          break;
        case 'L':
          md = SymlinkCreator;
          break;
        case 'D':
          md = PEDumper;
          break;
        case 'F':
          force = true;
          break;
        case 'J':
          tojson = true;
          break;
        case 'h':
          usage();
          exit(0);
          break;
        case 'v':
          bela::FPrintF(stderr, L"blast: %s\n", CLANGBUILDER_VERSION_FULL);
          exit(0);
          break;
        default:
          break;
        }
        return true;
      },
      ec);
  if (!result) {
    bela::FPrintF(stderr, L"blast ParseArgv error: %s\n", ec.message);
    return 1;
  }
  if (md == None) {
    usage();
    return 1;
  }
  if (md == SymlinkCreator) {
    if (pa.UnresolvedArgs().size() != 2) {
      bela::FPrintF(stderr,
                    L"blast --link parameters count must be equal to 2\n");
      return 1;
    }
    return createsymlink(pa.UnresolvedArgs()[0], pa.UnresolvedArgs()[1], force);
  }
  if (md == SymlinkReader) {
    if (pa.UnresolvedArgs().empty()) {
      bela::FPrintF(stderr, L"blast --readlink missing argument\n");
      return 1;
    }
    for (auto e : pa.UnresolvedArgs()) {
      std::wstring target;
      if (bela::LookupRealPath(e, target)) {
        bela::FPrintF(stdout, L"File: %s --> %s\n", e, target);
        continue;
      }
      bela::FPrintF(stderr, L"File: %s unable resolve target\n", e);
    }
    return 0;
  }
  if (md == PEDumper) {
    if (pa.UnresolvedArgs().empty()) {
      bela::FPrintF(stderr, L"blast --dump missing argument\n");
      return 1;
    }
    return dumpexe(pa.UnresolvedArgs()[0], tojson);
  }
  if (md == AnalyzeFile) {
    if (pa.UnresolvedArgs().empty()) {
      bela::FPrintF(stderr, L"blast --analyze missing argument\n");
      return 1;
    }
    for (auto e : pa.UnresolvedArgs()) {
      analyzefile(e, tojson);
    }
    return 0;
  }
  usage();
  return 1;
}