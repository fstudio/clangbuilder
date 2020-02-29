///
#include "baulk.hpp"
#include "fs.hpp"
#include <bela/numbers.hpp>
#include <bela/path.hpp>
#include <Msi.h>

namespace baulk::msi {

class Progressor {
public:
  Progressor() = default;
  Progressor(const Progressor &) = delete;
  Progressor &operator=(const Progressor) = delete;
  void Initialize(std::wstring_view msi) {
    auto pv = bela::SplitPath(msi);
    if (!pv.empty()) {
      name = pv.back();
    }
  }
  void Update(UINT total, UINT rate);

private:
  std::wstring name;
};

struct progress_field_t {
  int v[4];
};

inline int FGetInteger(wchar_t *&rpch) {
  wchar_t *pchPrev = rpch;
  while (*rpch && *rpch != ' ') {
    rpch++;
  }
  *rpch = '\0';
  int i = 0;
  bela::SimpleAtoi(pchPrev, &i);
  return i;
}

bool parse_progress_string(LPWSTR sz, progress_field_t &field) {
  auto pch = sz;
  if (*pch == 0) {
    return false;
  }
  while (*pch != 0) {
    wchar_t ch = *pch++;
    pch++;
    pch++;
    switch (ch) {
    case '1':
      if (isdigit(*pch) == 0) {
        return false;
      }
      field.v[0] = *pch++ - '0';
      break;
    case '2':
      break;
    case '3':
      break;
    case '4':
      break;
    default:
      return false;
    }
    pch++;
  }
  return true;
}

// install_ui_callback
INT WINAPI install_ui_callback(LPVOID ctx, UINT iMessageType,
                               LPCWSTR szMessage) {
  return 0;
}

bool decompress(std::wstring_view msi, std::wstring_view outdir,
                bela::error_code &ec) {
  auto cmd = bela::StringCat(L"ACTION=ADMIN TARGETDIR=\"", outdir, L"\"");
  MsiSetInternalUI(
      INSTALLUILEVEL(INSTALLUILEVEL_NONE | INSTALLUILEVEL_SOURCERESONLY),
      nullptr);
  // https://docs.microsoft.com/en-us/windows/win32/api/msi/nf-msi-msisetexternaluiw
  MsiSetExternalUIW(
      install_ui_callback,
      INSTALLLOGMODE_PROGRESS | INSTALLLOGMODE_FATALEXIT |
          INSTALLLOGMODE_ERROR | INSTALLLOGMODE_WARNING | INSTALLLOGMODE_USER |
          INSTALLLOGMODE_INFO | INSTALLLOGMODE_RESOLVESOURCE |
          INSTALLLOGMODE_OUTOFDISKSPACE | INSTALLLOGMODE_ACTIONSTART |
          INSTALLLOGMODE_ACTIONDATA | INSTALLLOGMODE_COMMONDATA |
          INSTALLLOGMODE_PROGRESS | INSTALLLOGMODE_INITIALIZE |
          INSTALLLOGMODE_TERMINATE | INSTALLLOGMODE_SHOWDIALOG,
      nullptr);
  if (MsiInstallProductW(msi.data(), cmd.data()) != ERROR_SUCCESS) {
    ec = bela::make_system_error_code();
    return false;
  }
  return true;
}

bool initialize(std::wstring_view path) {
  bela::error_code ec;
  if (!baulk::fs::matched_remove(path, L"*.msi", ec)) {
    //
    return false;
  }
  baulk::fs::recurse_remove(bela::StringCat(path, L"\\Windows"), ec); //
  constexpr std::wstring_view destdirs[] = {
      L"\\Program Files", L"\\ProgramFiles64", L"\\PFiles", L"\\Files"};
  for (auto d : destdirs) {
    auto sd = bela::StringCat(path, d);
    if (!bela::PathExists(sd)) {
      continue;
    }
    if (baulk::fs::movefrom_unique_subdir(sd, path, ec)) {
      return !ec;
    }
  }
  return true;
}

} // namespace baulk::msi