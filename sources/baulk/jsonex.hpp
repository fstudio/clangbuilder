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

template <typename Integer>
inline bool BindToInteger(nlohmann::json &j, std::string_view name,
                          Integer &i) {
  if (auto it = j.find(name); it != j.end()) {
    b = it->get<Integer>();
    return true;
  }
  return false;
}

inline bool BindTo(nlohmann::json &j, std::string_view name, bool &b) {
  if (auto it = j.find(name); it != j.end()) {
    b = it->get<bool>();
    return true;
  }
  return false;
}
} // namespace baulk::json

#endif