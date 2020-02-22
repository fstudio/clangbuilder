// Windows download utils
#include <bela/base.hpp>
#include <bela/env.hpp>
#include <bela/finaly.hpp>
#include <winhttp.h>
#include <cstdio>
#include <cstdlib>

inline void Free(HINTERNET &h) {
  if (h != nullptr) {
    WinHttpCloseHandle(h);
  }
}

// TODO progress
bool WinGetInternal(std::wstring_view scheme, std::wstring_view hostname,
                    std::wstring_view urlpath, std::wstring_view dest,
                    bela::error_code ec) {
  FILE *fd = nullptr;
  auto err = _wfopen_s(&fd, dest.data(), L"wb");
  if (err != 0) {
    ec = bela::make_error_code(-1, L"open failed status: ", err);
    return false;
  }
  HINTERNET hSession = nullptr;
  HINTERNET hConnect = nullptr;
  HINTERNET hRequest = nullptr;
  auto deleter = bela::final_act([&] {
    Free(hSession);
    Free(hConnect);
    Free(hRequest);
    fclose(fd);
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
  size_t total_downloaded_size = 0;
  DWORD dwSize = 0;
  std::vector<char> buf;
  buf.reserve(64 * 1024);
  do {
    DWORD downloaded_size = 0;
    if (WinHttpQueryDataAvailable(hRequest, &dwSize) != TRUE) {
      ec = bela::make_system_error_code();
      return false;
    }
    if (buf.size() < dwSize) {
      buf.resize(static_cast<size_t>(dwSize) * 2);
    }
    if (WinHttpReadData(hRequest, (LPVOID)buf.data(), dwSize,
                        &downloaded_size) != TRUE) {
      ec = bela::make_system_error_code();
      return false;
    }
    fwrite(buf.data(), 1, downloaded_size, fd);
    total_downloaded_size += downloaded_size;
  } while (dwSize > 0);
  fflush(fd);
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
  if (WinHttpCrackUrl(url.data(), url.size(), 0, &urlcomp) != TRUE) {
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