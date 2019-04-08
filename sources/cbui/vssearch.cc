//////////
#include "inc/vssearch.hpp"
#include "inc/json.hpp"
#include "inc/comutils.hpp"
#include "inc/vssetup.hpp"

bool VisualStudioSeacher::EnterpriseWDK(std::wstring_view root,
                                        vssetup::VSInstance &vsi) {
  auto ej = base::strcat(root, L"\\config\\ewdk.json");
  if (!PathFileExistsW(ej.data())) {
    ej = base::strcat(root, L"\\config\\ewdk.template.json");
    if (!PathFileExistsW(ej.data())) {
      return false;
    }
  }
  try {
    std::ifstream fs;
    fs.open(ej, std::ios::binary);
    auto j = nlohmann::json::parse(fs);
    auto path = j["Path"].get<std::string>();
    auto version = j["Version"].get<std::string>();
    auto vsversion = j["VisualStudioVersion"].get<std::string>();
    auto vsproduct = j["VisualStudio"].get<std::string>();
    auto wpath = clangbuilder::utf8towide(path);
    if (!PathFileExistsW(wpath.c_str())) {
      return false;
    }
    auto wvsver = clangbuilder::utf8towide(vsversion);
    vsi.DisplayName = base::strcat(
        L"Visual Studio BuildTools ", clangbuilder::utf8towide(vsproduct),
        L" (Enterprise WDK ", clangbuilder::utf8towide(version), L")");
    vsi.Version.assign(wvsver);
    vsi.InstanceId.assign(L"VisualStudio.EWDK");
  } catch (const std::exception &e) {
    fprintf(stderr, "%s\n", e.what());
    return false;
  }
  return true;
}

bool VisualStudioSeacher::Execute(std::wstring_view root) {
  vssetup::VisualStudioNativeSearcher vns;
  bool foundewdk = false;

  if (!vns.GetVSInstanceAll(instances)) {
    return false;
  }
  for (const auto &i : instances) {
    if (i.IsEnterpriseWDK) {
      return true;
    }
  }
  vssetup::VSInstance vsi;
  if (EnterpriseWDK(root, vsi)) {
    instances.push_back(std::move(vsi));
    std::sort(instances.begin(), instances.end());
  }
  return true;
}
