///

#include <optional>
#include <filesystem>
#include <bela/path.hpp>
#include <bela/base.hpp>
#include <bela/match.hpp>
#include <bela/strcat.hpp>

namespace baulk {

bool IsExecutableSuffix(std::wstring_view name) {
  constexpr std::wstring_view suffixs[] = {L".exe", L".com", L".bat", L".cmd"};
  for (const auto s : suffixs) {
    if (bela::EndsWithIgnoreCase(name, s)) {
      return true;
    }
  }
  return false;
}

bool IsExecutablePath(std::wstring_view p) {
  WIN32_FIND_DATAW wfd;
  auto findstr = bela::StringCat(p, L"\\*");
  HANDLE hFind = FindFirstFileW(findstr.c_str(), &wfd);
  if (hFind == INVALID_HANDLE_VALUE) {
    return false; /// Not found
  }
  do {
    if ((wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0 &&
        IsExecutableSuffix(wfd.cFileName)) {
      FindClose(hFind);
      return true;
    }
  } while (FindNextFileW(hFind, &wfd));
  FindClose(hFind);
  return false;
}

std::optional<std::wstring> FindExecutablePath(std::wstring_view p) {
  if (!bela::PathExists(p, bela::FileAttribute::Dir)) {
    return std::nullopt;
  }
  if (IsExecutablePath(p)) {
    return std::make_optional<std::wstring>(p);
  }
  auto p2 = bela::StringCat(p, L"\\bin");
  if (IsExecutablePath(p2)) {
    return std::make_optional(std::move(p2));
  }
  p2 = bela::StringCat(p, L"\\cmd");
  if (IsExecutablePath(p2)) {
    return std::make_optional(std::move(p2));
  }
  return std::nullopt;
}
} // namespace baulk