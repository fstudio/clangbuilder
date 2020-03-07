///
#ifndef BAULK_XML_HPP
#define BAULK_XML_HPP
#include <bela/base.hpp>
#include <bela/strip.hpp>
#define PUGIXML_HEADER_ONLY 1
#define PUGIXML_WCHAR_MODE 1
#include "details/pugixml/pugixml.hpp"

namespace baulk::xml {
using XmlDocument = pugi::xml_document;

inline bool ParseSdkVersion(std::wstring_view manifest, std::wstring &version,
                            bela::error_code &ec) {
  baulk::xml::XmlDocument doc;
  auto xr = doc.load_file(manifest.data());
  if (!xr) {
    ec = bela::make_error_code(1, bela::ToWide(xr.description()));
    return false;
  }
  std::wstring_view pi =
      doc.child(L"FileList").attribute(L"PlatformIdentity").as_string();
  if (pi.empty()) {
    ec = bela::make_error_code(1, L"no FileList.PlatformIdentity");
    return false;
  }
  constexpr std::wstring_view prefix = L"UAP, Version=";
  if (!bela::ConsumePrefix(&pi, prefix)) {
    ec = bela::make_error_code(1, L"not startswith 'UAP, Version='");
    return false;
  }
  version = pi;
  return true;
}

} // namespace baulk::xml

#endif