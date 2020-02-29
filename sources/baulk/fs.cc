///
#include "fs.hpp"
#include <bela/path.hpp>

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

bool recurse_remove(std::wstring_view dir, bela::error_code &ec) {
  Finder finder;
  if (!finder.First(dir, L"*", ec)) {
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
    if (!recurse_remove(p, ec)) {
      return false;
    }
  } while (finder.Next());
  if (RemoveDirectoryW(dir.data()) != TRUE) {
    ec = bela::make_system_error_code();
    return false;
  }
  return true;
}

bool matched_remove(std::wstring_view dir, std::wstring_view pattern,
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
    if (!recurse_remove(p, ec)) {
      return false;
    }
  } while (finder.Next());
  return true;
}

std::optional<std::wstring_view> unique_subdir(std::wstring_view dir) {
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

bool childs_moveto(std::wstring_view dir, std::wstring_view dest,
                   bela::error_code &ec) {
  Finder finder;
  if (!finder.First(dir, L"*", ec)) {
    return false;
  }
  if (!bela::PathExists(dest)) {
    if (CreateDirectoryW(dest.data(), nullptr) != TRUE) {
      ec = bela::make_system_error_code();
      return false;
    }
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

bool movefrom_unique_subdir(std::wstring_view dir, std::wstring_view dest,
                            bela::error_code &ec) {
  auto subdir = unique_subdir(dir);
  if (!subdir) {
    return true;
  }
  if (!childs_moveto(*subdir, dest, ec)) {
    return false;
  }
  RemoveDirectoryW(subdir->data());
  return true;
}

} // namespace baulk::fs