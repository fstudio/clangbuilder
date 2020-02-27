///
#ifndef BAULK_HPP
#define BAULK_HPP
#include <bela/base.hpp>

namespace baulk {
std::optional<std::wstring> WinGetInternal(std::wstring_view url,
                                           std::wstring_view workdir,
                                           bool avoidoverwrite,
                                           bela::error_code ec);
} // namespace baulk

#endif