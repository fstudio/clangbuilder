///
#ifndef BAULK_HPP
#define BAULK_HPP
#include <bela/base.hpp>

namespace baulk {
bool WinGetInternal(std::wstring_view url, std::wstring_view dest,
                    bela::error_code ec);
}

#endif