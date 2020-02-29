///
#include <bela/base.hpp>
#include <bela/path.hpp>
#include "process.hpp"

namespace baulk::zip {
inline std::optional<std::wstring> lookup_pwsh(bela::error_code &ec) {
  std::wstring pwsh;
  if (bela::ExecutableExistsInPath(L"pwsh.exe", pwsh)) {
    return std::make_optional(std::move(pwsh));
  }
  // Powershell
  if (bela::ExecutableExistsInPath(L"powershell.exe", pwsh)) {
    return std::make_optional(std::move(pwsh));
  }
  return std::nullopt;
}

bool pwsh_decompress(std::wstring_view src, std::wstring_view outdir,
                     bela::error_code &ec) {
  auto pwsh = lookup_pwsh(ec);
  if (!pwsh) {
    return false;
  }
  auto command = bela::StringCat(L"Expand-Archive -Path \"", src,
                                 L"\" -DestinationPath \"", outdir, L"\"");
  baulk::Process process;
  if (process.Execute(*pwsh, L"-Command", command) != 0) {
    return false;
  }
  return true;
}

bool decompress(std::wstring_view src, std::wstring_view outdir,
                bela::error_code &ec) {

  return true;
}
bool initialize(std::wstring_view path) {
  //
  return true;
}
} // namespace baulk::zip