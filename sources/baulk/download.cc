/// baulk download utils
//
#include "process.hpp"
#include <bela/path.hpp>

namespace baulk {
std::optional<std::wstring> FindCURL() {
  std::wstring curlexe;
  if (bela::ExecutableExistsInPath(L"curl.exe", curlexe)) {
    return std::make_optional(std::move(curlexe));
  }
  return std::nullopt;
}
} // namespace baulk
