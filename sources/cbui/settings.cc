/////
#include "inc/settings.hpp"
#include "inc/json.hpp"
#include "inc/systemtools.hpp"

bool Settings::Initialize(std::wstring_view root) {
  auto file = base::strcat(root, L"\\config\\settings.json");
  clangbuilder::FD fd;
  if (_wfopen_s(&fd.fd, file.data(), L"rb") != 0) {
    return false;
  }
  try {
    auto j = nlohmann::json::parse(fd.P());
    auto it = j.find("SetWindowCompositionAttribute");
    if (it != j.end()) {
      SetWindowCompositionAttribute_ =
          j["SetWindowCompositionAttribute"].get<bool>();
    }
  } catch (const std::exception &e) {
    fprintf(stderr, "%s\n", e.what());
    return false;
  }
  return true;
}