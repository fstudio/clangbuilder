#include "pch.h"
#include <string_view>
#include <winrt/Windows.Data.Json.h>

using namespace winrt;
using namespace Windows::Data;
using namespace Windows::Data::Json;

bool VisualStudioSearch(std::wstring_view root) {
  auto lockfile = std::wstring(root).append(
      L"\\bin\\utils\\msvc\\VisualCppTools.lock.json");
  auto jo = JsonObject::Parse(L"{}");
  return true;
}