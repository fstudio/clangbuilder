#include <bela/match.hpp>
#include <bela/strcat.hpp>
#include <bela/base.hpp>
#include <bela/path.hpp>
#include <optional>

inline bool DirSkipFaster(const wchar_t *dir) {
  return (dir[0] == L'.' &&
          (dir[1] == L'\0' || (dir[1] == L'.' && dir[2] == L'\0')));
}

bool RemoveAll(std::wstring_view dir) {
  WIN32_FIND_DATAW wfd;
  auto fstr = bela::StringCat(dir, L"\\*");
  HANDLE hFind = FindFirstFileW(fstr.data(), &wfd);
  if (hFind == INVALID_HANDLE_VALUE) {
    return false;
  }
  do {
    if (DirSkipFaster(wfd.cFileName)) {
      continue;
    }
    auto p = bela::StringCat(dir, L"\\", wfd.cFileName);
    if ((wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
      DeleteFileW(p.data());
      continue;
    }
    RemoveAll(p);
  } while (FindNextFileW(hFind, &wfd));
  FindClose(hFind);
  RemoveDirectoryW(dir.data());
  return true;
}

std::optional<std::wstring> UniqueSubFolder(std::wstring_view dir) {
  int count = 0;
  WIN32_FIND_DATAW wfd;
  auto fstr = bela::StringCat(dir, L"\\*");
  HANDLE hFind = FindFirstFileW(fstr.data(), &wfd);
  if (hFind == INVALID_HANDLE_VALUE) {
    return std::nullopt;
  }
  std::wstring subdir;
  do {
    if (DirSkipFaster(wfd.cFileName)) {
      continue;
    }
    count++;
    if ((wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0 && count == 0) {
      subdir = bela::StringCat(dir, L"\\", wfd.cFileName);
    }
  } while (FindNextFileW(hFind, &wfd));
  FindClose(hFind);
  if (count == 1) {
    return std::make_optional(std::move(subdir));
  }
  return std::nullopt;
}

bool MoveFromSubFolder(std::wstring_view path, std::wstring_view dest,
                       bela::error_code &ec) {
  // move subdir to ..
  auto subdir = UniqueSubFolder(path);
  if (!subdir) {
    return true;
  }
  WIN32_FIND_DATAW wfd;
  auto fstr = bela::StringCat(*subdir, L"\\*");
  HANDLE hFind = FindFirstFileW(fstr.data(), &wfd);
  if (hFind == INVALID_HANDLE_VALUE) {
    ec = bela::make_system_error_code();
    return false;
  }
  do {
    if (DirSkipFaster(wfd.cFileName)) {
      continue;
    }
    auto src = bela::StringCat(*subdir, L"\\", wfd.cFileName);
    auto p = bela::StringCat(dest, L"\\", wfd.cFileName);
    MoveFileW(src.data(), p.data());
  } while (FindNextFileW(hFind, &wfd));
  FindClose(hFind);
  RemoveDirectoryW(subdir->data());
  return true;
}

// Initialize zip archive layout
bool InitializeZipArchive(std::wstring_view path) {
  bela::error_code ec;
  MoveFromSubFolder(path, path, ec);
  return !ec;
}

inline bool DeleteMsiArchive(std::wstring_view p) {
  WIN32_FIND_DATAW wfd;
  auto findstr = bela::StringCat(p, L"\\*.msi");
  HANDLE hFind = FindFirstFileW(findstr.c_str(), &wfd);
  if (hFind == INVALID_HANDLE_VALUE) {
    return false; /// Not found
  }
  do {
    if ((wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0) {
      auto msi = bela::StringCat(p, L"\\", wfd.cFileName);
      DeleteFileW(msi.data());
    }
  } while (FindNextFileW(hFind, &wfd));
  FindClose(hFind);
  return true;
}

// cleanup msi archive
bool InitializeMsiArchive(std::wstring_view path) {
  if (!DeleteMsiArchive(path)) {
    return false;
  }
  auto windir = bela::StringCat(path, L"\\Windows");
  RemoveAll(windir);
  constexpr std::wstring_view msidirs[] = {
      L"\\Program Files", L"\\ProgramFiles64", L"\\PFiles", L"\\Files"};
  for (const auto d : msidirs) {
    auto sd = bela::StringCat(path, d);
    if (!bela::PathExists(sd)) {
      continue;
    }
    bela::error_code ec;
    if (MoveFromSubFolder(sd, path, ec)) {
      return !ec;
    }
  }
  return false;
}