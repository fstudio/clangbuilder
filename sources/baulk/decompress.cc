#include <bela/path.hpp>
#include "baulk.hpp"
#include "decompress.hpp"
#include "fs.hpp"

namespace baulk {

namespace standard {
bool Regularize(std::wstring_view path) {
  bela::error_code ec;
  // TODO some zip code
  return baulk::fs::MoveFromUniqueSubdir(path, path, ec);
}
} // namespace standard

namespace exe {
bool Decompress(std::wstring_view src, std::wstring_view outdir,
                bela::error_code &ec) {
  if (!baulk::fs::RecurseMakeDir(outdir)) {
    ec = bela::make_error_code(-1, L"unable recurse mkdir: ", outdir);
    return false;
  }
  auto fn = baulk::fs::ParseFilename(src);
  auto newfile = bela::StringCat(outdir, L"\\", fn);
  auto nold = bela::StringCat(newfile, L".old");
  if (bela::PathExists(newfile)) {
    if (MoveFileW(newfile.data(), nold.data()) != TRUE) {
      ec = bela::make_system_error_code();
      return false;
    }
  }
  if (MoveFileW(src.data(), newfile.data()) != TRUE) {
    ec = bela::make_system_error_code();
    return false;
  }
  return true;
}
bool Regularize(std::wstring_view path) {
  bela::error_code ec;
  baulk::fs::PathRemove(path, L"*.old", ec);
  return true;
}
} // namespace exe

} // namespace baulk