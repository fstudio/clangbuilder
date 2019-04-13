///////
#include "inc/apphelp.hpp"
#include "inc/apputils.hpp"
#include "inc/argvbuilder.hpp"
#include <windowsx.h> // box help
#include <vector>
#include "appui.hpp"

bool Execute(std::vector<std::wstring_view> &Argv) {
  if (Argv.empty()) {
    return false;
  }
  clangbuilder::argvbuilder ab;
  ab.assign(Argv[0]);
  for (size_t i = 1; i < Argv.size(); i++) {
    ab.append(Argv[i]);
  }
  PROCESS_INFORMATION pi;
  STARTUPINFO si;
  ZeroMemory(&si, sizeof(si));
  ZeroMemory(&pi, sizeof(pi));
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESHOWWINDOW;
  si.wShowWindow = SW_SHOW;
#if defined(_M_IX86) || defined(_M_ARM)
  //// Only x86,ARM on Windows 64
  clangbuilder::FsRedirection fsRedirection;
#endif
  if (CreateProcessW(nullptr, ab.command(), NULL, NULL, FALSE,
                     CREATE_NEW_CONSOLE | NORMAL_PRIORITY_CLASS, NULL, NULL,
                     &si, &pi) != TRUE) {
    return false;
  }
  CloseHandle(pi.hThread);
  CloseHandle(pi.hProcess);
  return true;
}

bool MainWindow::InitializeElemets() {
  // TODO initialize target
  tables.Targets = {L"x86", L"x64", L"ARM", L"ARM64"};
  tables.Configurations = {L"Release", L"MinSizeRel", L"RelWithDebInfo",
                           L"Debug"};
  tables.AddEngine(L"Ninja - MSVC", L"Ninja")
      .AddEngine(L"Ninja - Clang", L"NinjaIterate")
      .AddEngine(L"MSBuild - MSVC", L"MSBuild")
      .AddEngine(L"Ninja - Bootstrap", L"NinjaBootstrap");
  tables.Branches = {L"Mainline", L"Stable", L"Release"};
  return search.Execute(root);
}

LRESULT MainWindow::OnBuildNow(WORD wNotifyCode, WORD wID, HWND hWndCtl,
                               BOOL &bHandled) {
  auto pwshexe = settings.PwshExePath();
  if (pwshexe.empty()) {
    utils::PrivMessageBox(m_hWnd, L"Unable to find installed powershell",
                          L"Please check if powershell is installed correctly",
                          nullptr, utils::kFatalWindow);
    return S_FALSE;
  }

  auto vsindex_ = ComboBox_GetCurSel(hvsbox);
  if (vsindex_ < 0 || search.Size() <= (size_t)vsindex_) {
    return S_FALSE;
  }
  auto archindex_ = ComboBox_GetCurSel(htargetbox);
  if (archindex_ < 0 || tables.Targets.size() <= archindex_) {
    return S_FALSE;
  }

  auto flavor_ = ComboBox_GetCurSel(hconfigbox);
  if (flavor_ < 0 || tables.Configurations.size() <= flavor_) {
    return S_FALSE;
  }

  auto be = ComboBox_GetCurSel(hbuildbox);
  if (be < 0 || tables.Engines.size() <= be) {
    return S_FALSE;
  }

  auto bs = ComboBox_GetCurSel(hbranchbox);
  if (bs < 0 || tables.Branches.size() <= bs) {
    return S_FALSE;
  }

  std::vector<std::wstring_view> Argv;
  Argv.push_back(pwshexe);
  Argv.push_back(L"-NoLogo");
  Argv.push_back(L"-NoExit");
  Argv.push_back(L"-File");
  Argv.push_back(targetFile);
  Argv.push_back(L"-InstanceId");
  Argv.push_back(search.InstanceId(vsindex_));
  Argv.push_back(L"-InstallationVersion");
  Argv.push_back(search.InstallVersion(vsindex_));
  Argv.push_back(L"-Arch");
  Argv.push_back(tables.Targets[archindex_]);
  Argv.push_back(L"-Flavor");
  Argv.push_back(tables.Configurations[flavor_]);
  Argv.push_back(L"-Engine");
  Argv.push_back(tables.Engines[be].Value);
  Argv.push_back(L"-Branch");
  Argv.push_back(tables.Branches[bs]);

  if ((be == 1 || be == 3) && Button_GetCheck(hlibcxx) == BST_CHECKED) {
    Argv.push_back(L"-Libcxx");
  }

  if (Button_GetCheck(hlto) == BST_CHECKED) {
    Argv.push_back(L"-LTO");
  }

  if (Button_GetCheck(hsdklow) == BST_CHECKED) {
    Argv.push_back(L"-Sdklow");
  }

  if (Button_GetCheck(hcpack) == BST_CHECKED) {
    Argv.push_back(L"-Package");
  }

  if (Button_GetCheck(hlldb) == BST_CHECKED) {
    Argv.push_back(L"-LLDB");
  }

  if (Button_GetCheck(hcleanenv) == BST_CHECKED) {
    Argv.push_back(L"-ClearEnv");
  }
  if (!Execute(Argv)) {
    auto ec = base::make_system_error_code();
    utils::PrivMessageBox(m_hWnd, L"CreateProcess failed", ec.message.data(),
                          nullptr, utils::kFatalWindow);
  }
  return S_OK;
}

LRESULT MainWindow::OnStartupEnv(WORD wNotifyCode, WORD wID, HWND hWndCtl,
                                 BOOL &bHandled) {

  auto pwshexe = settings.PwshExePath();
  if (pwshexe.empty()) {
    utils::PrivMessageBox(m_hWnd, L"Unable to find installed powershell",
                          L"Please check if powershell is installed correctly",
                          nullptr, utils::kFatalWindow);
    return S_FALSE;
  }

  auto vsindex_ = ComboBox_GetCurSel(hvsbox);
  if (vsindex_ < 0 || search.Size() <= (size_t)vsindex_) {
    return S_FALSE;
  }
  auto archindex_ = ComboBox_GetCurSel(htargetbox);
  if (archindex_ < 0 || tables.Targets.size() <= archindex_) {
    return S_FALSE;
  }

  std::vector<std::wstring_view> Argv;
  Argv.push_back(pwshexe);
  Argv.push_back(L"-NoLogo");
  Argv.push_back(L"-NoExit");
  Argv.push_back(L"-File");
  Argv.push_back(targetFile);
  Argv.push_back(L"-Environment");
  Argv.push_back(L"-InstanceId");
  Argv.push_back(search.InstanceId(vsindex_));
  Argv.push_back(L"-InstallationVersion");
  Argv.push_back(search.InstallVersion(vsindex_));
  Argv.push_back(L"-Arch");
  Argv.push_back(tables.Targets[archindex_]);
  if (Button_GetCheck(hsdklow) == BST_CHECKED) {
    Argv.push_back(L"-Sdklow");
  }
  if (Button_GetCheck(hcleanenv) == BST_CHECKED) {
    Argv.push_back(L"-ClearEnv");
  }
  if (!Execute(Argv)) {
    auto ec = base::make_system_error_code();
    utils::PrivMessageBox(m_hWnd, L"CreateProcess failed", ec.message.data(),
                          nullptr, utils::kFatalWindow);
  }
  return S_OK;
}
