///
#ifndef BAULK_JSON_HPP
#define BAULK_JSON_HPP
#include <json.hpp>
#include <bela/base.hpp>

namespace baulk::json {
//
inline bool BindTo(nlohmann::json &j, std::string_view name,
                   std::wstring &out) {
  if (auto it = j.find(name); it != j.end()) {
    out = bela::ToWide(it->get_ref<const std::string &>());
    return true;
  }
  return false;
}
} // namespace baulk::json

#endif