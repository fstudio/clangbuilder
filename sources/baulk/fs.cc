///
#include "fs.hpp"
#include <bela/path.hpp>
#include <bela/match.hpp>

#ifndef SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE
#define SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE 0x2
#endif

namespace baulk::fs {
inline bool DirSkipFaster(const wchar_t *dir) {
  return (dir[0] == L'.' &&
          (dir[1] == L'\0' || (dir[1] == L'.' && dir[2] == L'\0')));
}

class Finder {
public:
  Finder() noexcept = default;
  Finder(const Finder &) = delete;
  Finder &operator=(const Finder &) = delete;
  ~Finder() noexcept {
    if (hFind != INVALID_HANDLE_VALUE) {
      FindClose(hFind);
    }
  }
  const WIN32_FIND_DATAW &FD() const { return wfd; }
  bool Ignore() const { return DirSkipFaster(wfd.cFileName); }
  bool IsDir() const {
    return (wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
  }
  std::wstring_view Name() const { return std::wstring_view(wfd.cFileName); }
  bool Next() { return FindNextFileW(hFind, &wfd) == TRUE; }
  bool First(std::wstring_view dir, std::wstring_view suffix,
             bela::error_code &ec) {
    auto d = bela::StringCat(dir, L"\\", suffix);
    hFind = FindFirstFileW(d.data(), &wfd);
    if (hFind = INVALID_HANDLE_VALUE) {
      ec = bela::make_system_error_code();
      return false;
    }
    return true;
  }

private:
  HANDLE hFind{INVALID_HANDLE_VALUE};
  WIN32_FIND_DATAW wfd;
};

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
  bela::error_code ec;
  Finder finder;
  if (!finder.First(p, L"*", ec)) {
    return false;
  }
  do {
    if (finder.Ignore()) {
      continue;
    }
    if (finder.IsDir()) {
      continue;
    }
    if (IsExecutableSuffix(finder.Name())) {
      return true;
    }
  } while (finder.Next());
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
template <typename T>
[[nodiscard]] T unaligned_load(const void *_Ptr) { // load a _Ty from _Ptr
  static_assert(std::is_trivial_v<T>, "Unaligned loads require trivial types");
  T _Tmp;
  std::memcpy(&_Tmp, _Ptr, sizeof(_Tmp));
  return _Tmp;
}
//

bool PathPatternRemove(std::wstring_view dir, std::wstring_view pattern,
                       bela::error_code &ec) {

  Finder finder;
  if (!finder.First(dir, pattern, ec)) {
    return false;
  }
  do {
    if (finder.Ignore()) {
      continue;
    }
    auto p = bela::StringCat(dir, L"\\", finder.Name());
    if (!finder.IsDir()) {
      if (DeleteFileW(p.data()) != TRUE) {
        ec = bela::make_system_error_code();
        return false;
      }
      continue;
    }
    if (!PathRemove(p, ec)) {
      return false;
    }
  } while (finder.Next());
  return true;
}

std::optional<std::wstring_view> SearchUniqueSubdir(std::wstring_view dir) {
  Finder finder;
  bela::error_code ec;
  if (!finder.First(dir, L"*", ec)) {
    return std::nullopt;
  }
  int count = 0;
  std::wstring subdir;
  do {
    if (finder.Ignore()) {
      continue;
    }
    auto p = bela::StringCat(dir, L"\\", finder.Name());
    count++;
    if (!finder.IsDir()) {
      return std::nullopt;
    }
    if (count == 1) {
      subdir = bela::StringCat(dir, L"\\", finder.Name());
    }
  } while (finder.Next());
  if (count == 1) {
    return std::make_optional(std::move(subdir));
  }
  return std::nullopt;
}

bool ChildsMoveTo(std::wstring_view dir, std::wstring_view dest,
                  bela::error_code &ec) {
  Finder finder;
  if (!finder.First(dir, L"*", ec)) {
    return false;
  }
  if (!MakeDir(dest, ec)) {
    ec = bela::make_error_code(-1, L"unable recurse mkdir: ", dest);
    return false;
  }
  do {
    if (finder.Ignore()) {
      continue;
    }
    auto name = finder.Name();
    auto src = bela::StringCat(dir, L"\\", name);
    auto p = bela::StringCat(dest, L"\\", name);
    MoveFileW(src.data(), p.data());
  } while (finder.Next());
  return true;
}

bool MoveFromUniqueSubdir(std::wstring_view dir, std::wstring_view dest,
                          bela::error_code &ec) {
  auto subdir = SearchUniqueSubdir(dir);
  if (!subdir) {
    return true;
  }
  if (!ChildsMoveTo(*subdir, dest, ec)) {
    return false;
  }
  RemoveDirectoryW(subdir->data());
  return true;
}

} // namespace baulk::fs