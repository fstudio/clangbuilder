//////////
#ifndef CLANGBUILDER_BLAST_HPP
#define CLANGBUILDER_BLAST_HPP
#include <string_view>
#include <string>
#include <cstdint>

namespace blast {
enum Mode {
  None = 0, //
  SymlinkCreator,
  SymlinkReader,
  PEDumper
};
struct Options {
  Mode m; ///
};
} // namespace blast

#endif