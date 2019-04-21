#ifndef PEAZ_PE_HPP
#define PEAZ_PE_HPP
#pragma once
#include "../include/base.hpp"

namespace pecoff {

class memview {
public:
  static constexpr std::size_t npos = SIZE_MAX;
  memview() = default;
  memview(const char *d, std::size_t l) : data_(d), size_(l) {}
  memview(const memview &other) {
    data_ = other.data_;
    size_ = other.size_;
  }

  template <size_t ArrayLen> bool startswith(const uint8_t (&bv)[ArrayLen]) {
    return (size_ >= ArrayLen && memcmp(data_, bv, ArrayLen) == 0);
  }

  bool startswith(std::string_view sv) {
    if (sv.size() > size_) {
      return false;
    }
    return (memcmp(data_, sv.data(), sv.size()) == 0);
  }

  bool startswith(const void *p, size_t n) {
    if (n > size_) {
      return false;
    }
    return (memcmp(data_, p, n) == 0);
  }

  bool startswith(memview mv) {
    if (mv.size_ > size_) {
      return false;
    }
    return (memcmp(data_, mv.data_, mv.size_) == 0);
  }
  bool indexswith(std::size_t offset, std::string_view sv) const {
    if (offset > size_) {
      return false;
    }
    return memcmp(data_ + offset, sv.data(), sv.size()) == 0;
  }
  memview submv(std::size_t pos, std::size_t n = npos) {
    return memview(data_ + pos, (std::min)(n, size_ - pos));
  }
  std::size_t size() const { return size_; }
  const char *data() const { return data_; }
  std::string_view sv() { return std::string_view(data_, size_); }
  unsigned char operator[](const std::size_t off) const {
    if (off >= size_) {
      return UCHAR_MAX;
    }
    return (unsigned char)data_[off];
  }
  template <typename T> const T *cast(size_t off) {
    if (off + sizeof(T) >= size_) {
      return nullptr;
    }
    return reinterpret_cast<const T *>(data_ + off);
  }

private:
  const char *data_{nullptr};
  std::size_t size_{0};
};

class mapview {
public:
  static constexpr auto nullfile_t = INVALID_HANDLE_VALUE;
  static void Close(HANDLE handle) {
    if (handle != nullfile_t) {
      CloseHandle(handle);
    }
  }

  mapview() = default;
  mapview(const mapview &) = delete;
  mapview &operator=(const mapview &) = delete;
  ~mapview() {
    if (data_ != nullptr) {
      ::UnmapViewOfFile(data_);
    }
    Close(FileMap);
    Close(FileHandle);
  }
  base::error_code mapfile(std::wstring_view file, std::size_t minsize = 1,
                           std::size_t maxsize = SIZE_MAX) {
#ifndef _M_X64
    FsDisableRedirection fdr;
#endif
    if ((FileHandle = CreateFileW(file.data(), GENERIC_READ,
                                  FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                                  OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL,
                                  nullptr)) == nullfile_t) {
      return base::make_system_error_code();
    }
    LARGE_INTEGER li;
    if (GetFileSizeEx(FileHandle, &li) != TRUE) {
      return base::make_system_error_code();
    }
    if ((std::size_t)li.QuadPart < minsize) {
      return base::make_error_code(L"filesize too small");
    }
    if ((FileMap = CreateFileMappingW(FileHandle, nullptr, PAGE_READONLY, 0, 0,
                                      nullptr)) == nullfile_t) {
      return base::make_system_error_code();
      ;
    }
    size_ = (size_t)li.QuadPart > maxsize ? maxsize : (size_t)li.QuadPart;
    auto baseAddr = MapViewOfFile(FileMap, FILE_MAP_READ, 0, 0, size_);
    if (baseAddr == nullptr) {
      return base::make_system_error_code();
      ;
    }
    data_ = reinterpret_cast<char *>(baseAddr);
    return base::error_code{};
  }
  std::size_t size() const { return size_; }
  const char *data() const { return data_; }
  unsigned char operator[](const std::size_t off) const {
    if (off >= size_) {
      return 255;
    }
    return (unsigned char)data_[off];
  }
  bool startswith(const char *prefix, size_t pl) const {
    if (pl >= size_) {
      return false;
    }
    return memcmp(data_, prefix, pl) == 0;
  }
  bool startswith(std::string_view sv) const {
    return startswith(sv.data(), sv.size());
  }
  bool indexswith(std::size_t offset, std::string_view sv) const {
    if (offset > size_) {
      return false;
    }
    return memcmp(data_ + offset, sv.data(), sv.size()) == 0;
  }

  template <typename T> const T *cast(size_t off) {
    if (off + sizeof(T) >= size_) {
      return nullptr;
    }
    return reinterpret_cast<const T *>(data_ + off);
  }

  memview subview(size_t off) {
    if (off >= size_) {
      return memview();
    }
    return memview(data_ + off, size_ - off);
  }

private:
  HANDLE FileHandle{nullfile_t};
  HANDLE FileMap{nullfile_t};
  char *data_{nullptr};
  std::size_t size_{0};
};

struct pe_version_t {
  uint16_t major{0};
  uint16_t minor{0};
  std::wstring strversion() { return base::StringCat(major, L".", minor); }
};

struct pe_minutiae_t {
  std::wstring machine;
  std::wstring subsystem;
  std::wstring clrmsg;
  std::vector<std::wstring> characteristics;
  std::vector<std::wstring> depends; /// DLL required
  pe_version_t osver;
  pe_version_t linkver;
  pe_version_t imagever;
  bool isdll;
  std::wstring dump() {
    std::wstring s;
    s.append(L"Machine:         ")
        .append(machine)
        .append(L"\nSubsystem:        ")
        .append(subsystem)
        .append(L"\nOS Version:       ")
        .append(osver.strversion())
        .append(L"\nLink Version:     ")
        .append(linkver.strversion())
        .append(L"\nImage Version:    ")
        .append(imagever.strversion());
    if (!clrmsg.empty()) {
      s.append(L"\nCLR Details:      ").append(clrmsg);
    }
    if (!characteristics.empty()) {
      s.append(L"\nCharacteristics:  ");
      s.append(characteristics[0]);
      for (size_t n = 1; n < characteristics.size(); n++) {
        s.append(L"\n                  ").append(characteristics[n]);
      }
      s.append(L"\n");
    }
    if (!depends.empty()) {
      s.append(L"\nDepends:          ");
      s.append(depends[0]);
      for (size_t n = 1; n < depends.size(); n++) {
        s.append(L"\n                  ").append(depends[n]);
      }
    }
    return s;
  }
};
std::optional<pe_minutiae_t> inquisitive_pecoff(std::wstring_view sv,
                                                base::error_code &ec);
} // namespace pecoff

#endif
