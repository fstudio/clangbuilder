#ifndef BAULK_FS_HPP
#define BAULK_FS_HPP
#include <bela/base.hpp>
#include <optional>
#include <string_view>

namespace baulk::fs {
bool IsExecutablePath(std::wstring_view p);
std::optional<std::wstring> FindExecutablePath(std::wstring_view p);
bool PathRecurseRemove(std::wstring_view dir, bela::error_code &ec);
bool PathRemove(std::wstring_view dir, std::wstring_view pattern,
                bela::error_code &ec);
std::optional<std::wstring_view> SearchUniqueSubdir(std::wstring_view dir);
bool ChildsMoveTo(std::wstring_view dir, std::wstring_view dest,
                  bela::error_code &ec);
bool MoveFromUniqueSubdir(std::wstring_view dir, std::wstring_view dest,
                          bela::error_code &ec);
} // namespace baulk::fs

#endif