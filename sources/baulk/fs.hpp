#ifndef BAULK_FS_HPP
#define BAULK_FS_HPP
#include <bela/base.hpp>
#include <optional>
#include <string_view>

namespace baulk::fs {
bool recurse_remove(std::wstring_view dir, bela::error_code &ec);
bool matched_remove(std::wstring_view dir, std::wstring_view pattern,
                    bela::error_code &ec);
std::optional<std::wstring_view> unique_subdir(std::wstring_view dir);
bool childs_moveto(std::wstring_view dir, std::wstring_view dest,
                   bela::error_code &ec);
bool movefrom_unique_subdir(std::wstring_view dir, std::wstring_view dest,
                            bela::error_code &ec);
} // namespace baulk::fs

#endif