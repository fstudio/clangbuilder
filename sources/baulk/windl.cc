// Windows download utils
#include <bela/base.hpp>
#include <bela/env.hpp>
#include <bela/finaly.hpp>
#include <bela/path.hpp>
#include <winhttp.h>
#include <cstdio>
#include <cstdlib>
#include "indicators.hpp"
#include "baulk.hpp"

namespace baulk {
inline void Free(HINTERNET &h) {
  if (h != nullptr) {
    WinHttpCloseHandle(h);
  }
}

class File {
public:
  File() = default;
  File(const File &) = delete;
  File &operator=(const File &) = delete;
  File(File &&o) {
    if (FileHandle != INVALID_HANDLE_VALUE) {
      CloseHandle(FileHandle);
    }
    FileHandle = o.FileHandle;
    path = o.path;
    o.FileHandle = INVALID_HANDLE_VALUE;
    o.path.clear();
  }
  File &operator=(File &&o) {
    if (FileHandle != INVALID_HANDLE_VALUE) {
      CloseHandle(FileHandle);
    }
    FileHandle = o.FileHandle;
    o.FileHandle = INVALID_HANDLE_VALUE;
    path = o.path;
    o.path.clear();
    return *this;
  }
  ~File() {
    Rollback(); // rollback
  }
  void Rollback() {
    if (FileHandle != INVALID_HANDLE_VALUE) {
      CloseHandle(FileHandle);
      FileHandle = INVALID_HANDLE_VALUE;
      auto part = bela::StringCat(path, L".part");
      DeleteFileW(part.data());
    }
  }
  bool Finish() {
    if (FileHandle == INVALID_HANDLE_VALUE) {
      SetLastError(ERROR_INVALID_HANDLE);
      return false;
    }
    CloseHandle(FileHandle);
    FileHandle = INVALID_HANDLE_VALUE;
    auto part = bela::StringCat(path, L".part");
    return (MoveFileW(part.data(), path.data()) == TRUE);
  }
  bool Write(const char *data, DWORD len) {
    DWORD dwlen = 0;
    if (WriteFile(FileHandle, data, len, &dwlen, nullptr) != TRUE) {
      return false;
    }
    return len == dwlen;
  }
  std::wstring_view FileName() const {
    auto sv = std::wstring_view(path);
    auto pos = sv.rfind('\\');
    if (pos == std::wstring::npos) {
      return L"NONE";
    }
    return sv.substr(pos);
  }
  static std::optional<File> MakeFile(std::wstring_view p,
                                      bela::error_code &ec) {
    File file;
    file.path = bela::PathCat(p); // Path cleanup
    auto part = bela::StringCat(file.path, L".part");
    file.FileHandle = ::CreateFileW(
        part.data(), FILE_GENERIC_READ | FILE_GENERIC_WRITE, FILE_SHARE_READ,
        nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file.FileHandle == INVALID_HANDLE_VALUE) {
      ec = bela::make_system_error_code();
      return std::nullopt;
    }
    return std::make_optional(std::move(file));
  }

private:
  HANDLE FileHandle{INVALID_HANDLE_VALUE};
  std::wstring path;
};

// TODO progress
bool WinGetInternal(std::wstring_view scheme, std::wstring_view hostname,
                    std::wstring_view urlpath, std::wstring_view dest,
                    bela::error_code ec) {
  HINTERNET hSession = nullptr;
  HINTERNET hConnect = nullptr;
  HINTERNET hRequest = nullptr;
  auto deleter = bela::final_act([&] {
    Free(hSession);
    Free(hConnect);
    Free(hRequest);
  });
  hSession =
      WinHttpOpen(L"Wget/5.0 (Baulk)", WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY,
                  WINHTTP_NO_PROXY_NAME, WINHTTP_NO_PROXY_BYPASS, 0);
  if (hSession == nullptr) {
    ec = bela::make_system_error_code();
    return false;
  }
  auto https_proxy_env = bela::GetEnv(L"HTTPS_PROXY");
  if (!https_proxy_env.empty()) {
    WINHTTP_PROXY_INFOW proxy;
    proxy.dwAccessType = WINHTTP_ACCESS_TYPE_NAMED_PROXY;
    proxy.lpszProxy = https_proxy_env.data();
    proxy.lpszProxyBypass = nullptr;
    WinHttpSetOption(hSession, WINHTTP_OPTION_PROXY, &proxy, sizeof(proxy));
  }
  DWORD secure_protocols(WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_2 |
                         WINHTTP_FLAG_SECURE_PROTOCOL_TLS1_3);
  WinHttpSetOption(hSession, WINHTTP_OPTION_SECURE_PROTOCOLS, &secure_protocols,
                   sizeof(secure_protocols));
  hConnect =
      WinHttpConnect(hSession, hostname.data(), INTERNET_DEFAULT_HTTPS_PORT, 0);
  if (hConnect == nullptr) {
    ec = bela::make_system_error_code();
    return false;
  }
  hRequest = WinHttpOpenRequest(
      hConnect, L"GET", urlpath.data(), nullptr, WINHTTP_NO_REFERER,
      WINHTTP_DEFAULT_ACCEPT_TYPES, WINHTTP_FLAG_SECURE);
  if (hRequest == nullptr) {
    ec = bela::make_system_error_code();
    return false;
  }
  if (WinHttpSendRequest(hRequest, WINHTTP_NO_ADDITIONAL_HEADERS, 0,
                         WINHTTP_NO_REQUEST_DATA, 0, 0, 0) != TRUE) {
    ec = bela::make_system_error_code();
    return false;
  }
  if (WinHttpReceiveResponse(hRequest, nullptr) != TRUE) {
    ec = bela::make_system_error_code();
    return false;
  }
  baulk::ProgressBar bar;
  wchar_t conlen[32];
  DWORD dwXsize = sizeof(conlen);
  if (WinHttpQueryHeaders(hRequest, WINHTTP_QUERY_CONTENT_LENGTH,
                          WINHTTP_HEADER_NAME_BY_INDEX, conlen, &dwXsize,
                          WINHTTP_NO_HEADER_INDEX) == TRUE) {
    uint64_t blen = 0;
    if (bela::SimpleAtoi({conlen, dwXsize}, &blen)) {
      bar.Maximum(blen);
    }
  }

  size_t total_downloaded_size = 0;
  DWORD dwSize = 0;
  std::vector<char> buf;
  buf.reserve(64 * 1024);
  auto file = File::MakeFile(dest, ec);
  bar.FileName(file->FileName());
  bar.Execute();
  auto finally = bela::finally([&] {
    // finish progressbar
    bar.Finish();
  });
  do {
    DWORD downloaded_size = 0;
    if (WinHttpQueryDataAvailable(hRequest, &dwSize) != TRUE) {
      ec = bela::make_system_error_code();
      bar.MarkFault();
      return false;
    }
    if (buf.size() < dwSize) {
      buf.resize(static_cast<size_t>(dwSize) * 2);
    }
    if (WinHttpReadData(hRequest, (LPVOID)buf.data(), dwSize,
                        &downloaded_size) != TRUE) {
      ec = bela::make_system_error_code();
      bar.MarkFault();
      return false;
    }
    file->Write(buf.data(), downloaded_size);
    total_downloaded_size += downloaded_size;
    bar.Update(total_downloaded_size);
  } while (dwSize > 0);
  file->Finish();
  bar.MarkCompleted();
  return true;
}

bool WinGetInternal(std::wstring_view url, std::wstring_view dest,
                    bela::error_code ec) {
  URL_COMPONENTSW urlcomp;
  ZeroMemory(&urlcomp, sizeof(urlcomp));
  urlcomp.dwStructSize = sizeof(urlcomp);
  urlcomp.dwSchemeLength = (DWORD)-1;
  urlcomp.dwHostNameLength = (DWORD)-1;
  urlcomp.dwUrlPathLength = (DWORD)-1;
  urlcomp.dwExtraInfoLength = (DWORD)-1;
  if (WinHttpCrackUrl(url.data(), static_cast<DWORD>(url.size()), 0,
                      &urlcomp) != TRUE) {
    ec = bela::make_system_error_code();
    return false;
  }
  std::wstring_view scheme{urlcomp.lpszScheme, urlcomp.dwSchemeLength};
  std::wstring hostname{urlcomp.lpszHostName, urlcomp.dwHostNameLength};
  std::wstring urlpath = bela::StringCat(
      std::wstring_view{urlcomp.lpszUrlPath, urlcomp.dwUrlPathLength},
      std::wstring_view{urlcomp.lpszExtraInfo, urlcomp.dwExtraInfoLength});
  return WinGetInternal(scheme, hostname, urlpath, dest, ec);
}
} // namespace baulk