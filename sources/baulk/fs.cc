///
#include "fs.hpp"
#include <bela/path.hpp>
#include <bela/match.hpp>

namespace baulk::fs {
inline bool DirSkipFaster(const wchar_t *dir) {
  return (dir[0] == L'.' &&
          (dir[1] == L'\0' || (dir[1] == L'.' && dir[2] == L'\0')));
}

std::wstring_view BaseNameView(std::wstring_view sv) {
  if (sv.empty()) {
    return L".";
  }
  auto pos = sv.find_last_not_of(bela::PathSeparator);
  if (pos == std::wstring_view::npos) {
    return L"/";
  }
  sv.remove_suffix(sv.size() - pos - 1);
  pos = sv.rfind(bela::PathSeparator);
  if (pos != std::wstring_view::npos) {
    sv.remove_prefix(pos + 1);
  }
  return std::wstring_view(sv.empty() ? L"." : sv);
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

    [[nodiscard]] inline bool IsDrivePrefix(const wchar_t *const first) {
  auto _Value = unaligned_load<unsigned int>(first);
  _Value &=
      0xFFFF'FFDFu; // transform lowercase drive letters into uppercase ones
  _Value -=
      (static_cast<unsigned int>(L':') << (sizeof(wchar_t) * CHAR_BIT)) | L'A';
  return _Value < 26;
}

[[nodiscard]] inline bool HasDriveLetterPrefix(const wchar_t *const _First,
                                               const wchar_t *const _Last) {
  // test if [_First, _Last) has a prefix of the form X:
  return _Last - _First >= 2 && IsDrivePrefix(_First);
}

[[nodiscard]] inline const wchar_t *
Find_root_name_end(const wchar_t *const _First, const wchar_t *const _Last) {
  // attempt to parse [_First, _Last) as a path and return the end of root-name
  // if it exists; otherwise, _First

  // This is the place in the generic grammar where library implementations have
  // the most freedom. Below are example Windows paths, and what we've decided
  // to do with them:
  // * X:DriveRelative, X:\DosAbsolute
  //   We parse X: as root-name, if and only if \ is present we consider that
  //   root-directory
  // * \RootRelative
  //   We parse no root-name, and \ as root-directory
  // * \\server\share
  //   We parse \\server as root-name, \ as root-directory, and share as the
  //   first element in relative-path. Technically, Windows considers all of
  //   \\server\share the logical "root", but for purposes of decomposition we
  //   want those split, so that
  //   path(R"(\\server\share)").replace_filename("other_share") is
  //   \\server\other_share
  // * \\?\device
  // * \??\device
  // * \\.\device
  //   CreateFile appears to treat these as the same thing; we will set the
  //   first three characters as root-name and the first \ as root-directory.
  //   Support for these prefixes varies by particular Windows version, but for
  //   the purposes of path decomposition we don't need to worry about that.
  // * \\?\UNC\server\share
  //   MSDN explicitly documents the \\?\UNC syntax as a special case. What
  //   actually happens is that the device Mup, or "Multiple UNC provider", owns
  //   the path \\?\UNC in the NT namespace, and is responsible for the network
  //   file access. When the user says \\server\share, CreateFile translates
  //   that into
  //   \\?\UNC\server\share to get the remote server access behavior. Because NT
  //   treats this like any other device, we have chosen to treat this as the
  //   \\?\ case above.
  if (_Last - _First < 2) {
    return _First;
  }

  if (HasDriveLetterPrefix(_First, _Last)) {
    // check for X: first because it's the most common root-name
    return _First + 2;
  }

  if (!bela::IsPathSeparator(_First[0])) {
    // all the other root-names start with a slash; check
    // that first because
    // we expect paths without a leading slash to be very common
    return _First;
  }

  // $ means anything other than a slash, including potentially the end of the
  // input
  if (_Last - _First >= 4 && bela::IsPathSeparator(_First[3]) &&
      (_Last - _First == 4 || !bela::IsPathSeparator(_First[4])) // \xx\$
      && ((bela::IsPathSeparator(_First[1]) &&
           (_First[2] == L'?' || _First[2] == L'.'))      // \\?\$ or \\.\$
          || (_First[1] == L'?' && _First[2] == L'?'))) { // \??\$
    return _First + 3;
  }

  if (_Last - _First >= 3 && bela::IsPathSeparator(_First[1]) &&
      !bela::IsPathSeparator(_First[2])) { // \\server
    return std::find_if(_First + 3, _Last, bela::IsPathSeparator);
  }

  // no match
  return _First;
}

[[nodiscard]] inline std::wstring_view
Parse_root_name(const std::wstring_view _Str) {
  // attempt to parse _Str as a path and return the root-name if it exists;
  // otherwise, an empty view
  const auto _First = _Str.data();
  const auto _Last = _First + _Str.size();
  return std::wstring_view(
      _First, static_cast<size_t>(Find_root_name_end(_First, _Last) - _First));
}

[[nodiscard]] inline const wchar_t *
Find_relative_path(const wchar_t *const _First, const wchar_t *const _Last) {
  // attempt to parse [_First, _Last) as a path and return the start of
  // relative-path
  return std::find_if_not(Find_root_name_end(_First, _Last), _Last,
                          bela::IsPathSeparator);
}

[[nodiscard]] inline const wchar_t *Find_filename(const wchar_t *const _First,
                                                  const wchar_t *_Last) {
  // attempt to parse [_First, _Last) as a path and return the start of filename
  // if it exists; otherwise, _Last
  const auto _Relative_path = Find_relative_path(_First, _Last);
  while (_Relative_path != _Last && !bela::IsPathSeparator(_Last[-1])) {
    --_Last;
  }

  return _Last;
}

std::wstring_view ParseFilename(const std::wstring_view _Str) {
  // attempt to parse _Str as a path and return the filename if it exists;
  // otherwise, an empty view
  const auto _First = _Str.data();
  const auto _Last = _First + _Str.size();
  const auto _Filename = Find_filename(_First, _Last);
  return std::wstring_view(_Filename, static_cast<size_t>(_Last - _Filename));
}

bool RecurseMakeDir(std::wstring_view p) {
  std::wstring tmp;
  tmp.reserve(p.size());
  auto cursor = p.data();
  const auto end = cursor + p.size();
  auto re = Find_relative_path(cursor, end);
  if (re != cursor && end - re >= 3 && IsDrivePrefix(re) &&
      bela::IsPathSeparator(re[2])) {
    re += 2;
  }
  tmp.append(cursor, re);
  cursor = re;
  bool createdlast = false;
  DWORD error = 0;
  while (cursor != end) {
    const auto addedend =
        std::find_if(std::find_if_not(cursor, end, bela::IsPathSeparator), end,
                     bela::IsPathSeparator);
    tmp.append(cursor, addedend);
    CreateDirectoryW(tmp.data(), nullptr);
    cursor = addedend;
  }
  return bela::PathExists(tmp, bela::FileAttribute::Dir);
}

bool PathRecurseRemove(std::wstring_view dir, bela::error_code &ec) {
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
    if (!PathRecurseRemove(p, ec)) {
      return false;
    }
  } while (finder.Next());
  if (RemoveDirectoryW(dir.data()) != TRUE) {
    ec = bela::make_system_error_code();
    return false;
  }
  return true;
}

bool PathRemove(std::wstring_view dir, std::wstring_view pattern,
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
    if (!PathRecurseRemove(p, ec)) {
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
  if (!RecurseMakeDir(dest)) {
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