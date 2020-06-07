//
#ifndef BELA_STR_REPLACE_HPP
#define BELA_STR_REPLACE_HPP
#pragma once
#include <string>
#include <utility>
#include <vector>
#include <string_view>

namespace bela {
[[nodiscard]] std::wstring
StrReplaceAll(std::wstring_view s,
              std::initializer_list<std::pair<std::wstring_view, std::wstring_view>> replacements);
template <typename StrToStrMapping>
[[nodiscard]] std::wstring StrReplaceAll(std::wstring_view s, const StrToStrMapping &replacements);
int StrReplaceAll(
    std::initializer_list<std::pair<std::wstring_view, std::wstring_view>> replacements,
    std::wstring *target);
// Implementation details only, past this point.
namespace strings_internal {

struct ViableSubstitution {
  std::wstring_view old;
  std::wstring_view replacement;
  size_t offset;

  ViableSubstitution(std::wstring_view old_str, std::wstring_view replacement_str,
                     size_t offset_val)
      : old(old_str), replacement(replacement_str), offset(offset_val) {}

  // One substitution occurs "before" another (takes priority) if either
  // it has the lowest offset, or it has the same offset but a larger size.
  bool OccursBefore(const ViableSubstitution &y) const {
    if (offset != y.offset)
      return offset < y.offset;
    return old.size() > y.old.size();
  }
};

// Build a vector of ViableSubstitutions based on the given list of
// replacements. subs can be implemented as a priority_queue. However, it turns
// out that most callers have small enough a list of substitutions that the
// overhead of such a queue isn't worth it.
template <typename StrToStrMapping>
std::vector<ViableSubstitution> FindSubstitutions(std::wstring_view s,
                                                  const StrToStrMapping &replacements) {
  std::vector<ViableSubstitution> subs;
  subs.reserve(replacements.size());

  for (const auto &rep : replacements) {
    using std::get;
    std::wstring_view old(get<0>(rep));

    size_t pos = s.find(old);
    if (pos == s.npos)
      continue;

    // Ignore attempts to replace "". This condition is almost never true,
    // but above condition is frequently true. That's why we test for this
    // now and not before.
    if (old.empty())
      continue;

    subs.emplace_back(old, get<1>(rep), pos);

    // Insertion sort to ensure the last ViableSubstitution comes before
    // all the others.
    size_t index = subs.size();
    while (--index && subs[index - 1].OccursBefore(subs[index])) {
      std::swap(subs[index], subs[index - 1]);
    }
  }
  return subs;
}

int ApplySubstitutions(std::wstring_view s, std::vector<ViableSubstitution> *subs_ptr,
                       std::wstring *result_ptr);

} // namespace strings_internal

template <typename StrToStrMapping>
std::wstring StrReplaceAll(std::wstring_view s, const StrToStrMapping &replacements) {
  auto subs = strings_internal::FindSubstitutions(s, replacements);
  std::wstring result;
  result.reserve(s.size());
  strings_internal::ApplySubstitutions(s, &subs, &result);
  return result;
}

template <typename StrToStrMapping>
int StrReplaceAll(const StrToStrMapping &replacements, std::wstring *target) {
  auto subs = strings_internal::FindSubstitutions(*target, replacements);
  if (subs.empty())
    return 0;

  std::wstring result;
  result.reserve(target->size());
  int substitutions = strings_internal::ApplySubstitutions(*target, &subs, &result);
  target->swap(result);
  return substitutions;
}

} // namespace bela

#endif
