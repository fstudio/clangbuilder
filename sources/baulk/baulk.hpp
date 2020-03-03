///
#ifndef BAULK_HPP
#define BAULK_HPP
#include <bela/base.hpp>

namespace baulk {
struct Package {
  std::wstring name;
  std::wstring description;
  std::wstring url;
  std::wstring version;
  std::vector<std::wstring> links;
  std::vector<std::wstring> launchers;
};
bool MakeLinks(std::wstring_view root, const baulk::Package &pkg,
               bela::error_code &ec);

std::optional<std::wstring> WinGetInternal(std::wstring_view url,
                                           std::wstring_view workdir,
                                           bool avoidoverwrite,
                                           bela::error_code ec);
} // namespace baulk

#endif