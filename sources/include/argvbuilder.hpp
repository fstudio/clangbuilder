/// ArgvBuilder
#ifndef CLANGBUIDER_ARGVBD_HPP
#define CLANGBUIDER_ARGVBD_HPP
#include <string>
#include <string_view>

namespace clangbuilder {
class ArgvBuilder {
public:
  ArgvBuilder() = default;
  ArgvBuilder(const ArgvBuilder &) = delete;
  ArgvBuilder &operator=(const ArgvBuilder &) = delete;
  ArgvBuilder &Assign(std::wstring_view a0) {
    args_.assign(Escape(a0));
    return *this;
  }
  ArgvBuilder &AssignNoEscape(std::wstring_view a0) {
    args_.assign(a0);
    return *this;
  }
  ArgvBuilder &Append(std::wstring_view a) {
    if (!args_.empty()) {
      args_.append(L" ");
    }
    args_.append(Escape(a));
    return *this;
  }
  const std::wstring &Args() const { return args_; }
  wchar_t *Command() { return args_.data(); }

private:
  std::wstring args_;
  std::wstring Escape(std::wstring_view ac);
};

inline std::wstring ArgvBuilder::Escape(std::wstring_view ac) {
  if (ac.empty()) {
    return L"\"\"";
  }
  bool hasspace = false;
  auto n = ac.size();
  for (auto c : ac) {
    switch (c) {
    case L'"':
    case L'\\':
      n++;
      break;
    case ' ':
    case '\t':
      hasspace = true;
      break;
    default:
      break;
    }
  }
  if (hasspace) {
    n += 2;
  }
  if (n == ac.size()) {
    return std::wstring(ac.data(), ac.size());
  }
  std::wstring buf;
  if (hasspace) {
    buf.push_back(L'"');
  }
  size_t slashes = 0;
  for (auto c : ac) {
    switch (c) {
    case L'\\':
      slashes++;
      buf.push_back(L'\\');
      break;
    case L'"': {
      for (; slashes > 0; slashes--) {
        buf.push_back(L'\\');
      }
      buf.push_back(L'\\');
      buf.push_back(c);
    } break;
    default:
      slashes = 0;
      buf.push_back(c);
      break;
    }
  }
  if (hasspace) {
    for (; slashes > 0; slashes--) {
      buf.push_back(L'\\');
    }
    buf.push_back(L'"');
  }
  return buf;
}

} // namespace clangbuilder

#endif
