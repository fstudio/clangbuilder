///////
#include <bela/base.hpp>
#include <bela/escapeargv.hpp>
#include <bela/picker.hpp>
#include <windowsx.h> // box help
#include <vector>
#include "appui.hpp"

bool Execute(wchar_t *command) {
  PROCESS_INFORMATION pi;
  STARTUPINFOW si;
  ZeroMemory(&si, sizeof(si));
  ZeroMemory(&pi, sizeof(pi));
  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESHOWWINDOW;
  si.wShowWindow = SW_SHOW;
#if defined(_M_IX86) || defined(_M_ARM)
  //// Only x86,ARM on Windows 64/ARM64
  clangbuilder::FsRedirection fsRedirection;
#endif
  if (CreateProcessW(nullptr, command, NULL, NULL, FALSE,
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
  return search.Execute(root, settings.EnterpriseWDK());
}

LRESULT MainWindow::OnBuildNow(WORD wNotifyCode, WORD wID, HWND hWndCtl,
                               BOOL &bHandled) {
  auto pwshexe = settings.PwshExePath();
  if (pwshexe.empty()) {
    bela::BelaMessageBox(m_hWnd, L"Unable to find installed powershell",
                         L"Please check if powershell is installed correctly",
                         nullptr, bela::mbs_t::FATAL);

    return S_FALSE;
  }

  auto vsindex_ = ComboBox_GetCurSel(hvsbox.hWnd);
  if (vsindex_ < 0 || search.Size() <= (size_t)vsindex_) {
    return S_FALSE;
  }
  auto archindex_ = ComboBox_GetCurSel(htargetbox.hWnd);
  if (archindex_ < 0 || tables.Targets.size() <= archindex_) {
    return S_FALSE;
  }

  auto flavor_ = ComboBox_GetCurSel(hconfigbox.hWnd);
  if (flavor_ < 0 || tables.Configurations.size() <= flavor_) {
    return S_FALSE;
  }

  auto be = ComboBox_GetCurSel(hbuildbox.hWnd);
  if (be < 0 || tables.Engines.size() <= be) {
    return S_FALSE;
  }

  auto bs = ComboBox_GetCurSel(hbranchbox.hWnd);
  if (bs < 0 || tables.Branches.size() <= bs) {
    return S_FALSE;
  }

  bela::EscapeArgv ea;
  if (!settings.Conhost().empty()) {
    ea.Assign(settings.Conhost());
    // ea.Append(L"--width");
    // ea.Append(L"90");
    // ea.Append(L"--height");
    // ea.Append(L"27");
  }
  ea.Append(pwshexe)
      .Append(L"-NoLogo")
      .Append(L"-NoExit")
      .Append(L"-File")
      .Append(targetFile)
      .Append(L"-InstanceId")
      .Append(search.InstanceId(vsindex_))
      .Append(L"-InstallationVersion")
      .Append(search.InstallVersion(vsindex_))
      .Append(L"-Arch")
      .Append(tables.Targets[archindex_])
      .Append(L"-Flavor")
      .Append(tables.Configurations[flavor_])
      .Append(L"-Engine")
      .Append(tables.Engines[be].Value)
      .Append(L"-Branch")
      .Append(tables.Branches[bs]);

  if ((be == 1 || be == 3) && Button_GetCheck(hlibcxx.hWnd) == BST_CHECKED) {
    ea.Append(L"-Libcxx");
  }

  if (Button_GetCheck(hlto.hWnd) == BST_CHECKED) {
    ea.Append(L"-LTO");
  }

  if (Button_GetCheck(hsdklow.hWnd) == BST_CHECKED) {
    ea.Append(L"-Sdklow");
  }

  if (Button_GetCheck(hcpack.hWnd) == BST_CHECKED) {
    ea.Append(L"-Package");
  }

  if (Button_GetCheck(hlldb.hWnd) == BST_CHECKED) {
    ea.Append(L"-LLDB");
  }

  if (Button_GetCheck(hcleanenv.hWnd) == BST_CHECKED) {
    ea.Append(L"-ClearEnv");
  }
  if (!Execute(ea.data())) {
    auto ec = bela::make_system_error_code();
    bela::BelaMessageBox(m_hWnd, L"CreateProcess failed", ec.message.data(),
                         nullptr, bela::mbs_t::FATAL);
  }
  return S_OK;
}

LRESULT MainWindow::OnStartupEnv(WORD wNotifyCode, WORD wID, HWND hWndCtl,
                                 BOOL &bHandled) {

  auto pwshexe = settings.PwshExePath();
  if (pwshexe.empty()) {
    bela::BelaMessageBox(m_hWnd, L"Unable to find installed powershell",
                         L"Please check if powershell is installed correctly",
                         nullptr, bela::mbs_t::FATAL);
    return S_FALSE;
  }

  auto vsindex_ = ComboBox_GetCurSel(hvsbox.hWnd);
  if (vsindex_ < 0 || search.Size() <= (size_t)vsindex_) {
    return S_FALSE;
  }
  auto archindex_ = ComboBox_GetCurSel(htargetbox.hWnd);
  if (archindex_ < 0 || tables.Targets.size() <= archindex_) {
    return S_FALSE;
  }

  bela::EscapeArgv ea;
  if (!settings.Conhost().empty()) {
    ea.Assign(settings.Conhost());
    // ea.Append(L"--width");
    // ea.Append(L"90");
    // ea.Append(L"--height");
    // ea.Append(L"27");
  }
  ea.Append(pwshexe)
      .Append(L"-NoLogo")
      .Append(L"-NoExit")
      .Append(L"-File")
      .Append(targetFile)
      .Append(L"-Environment")
      .Append(L"-InstanceId")
      .Append(search.InstanceId(vsindex_))
      .Append(L"-InstallationVersion")
      .Append(search.InstallVersion(vsindex_))
      .Append(L"-Arch")
      .Append(tables.Targets[archindex_]);
  if (Button_GetCheck(hsdklow.hWnd) == BST_CHECKED) {
    ea.Append(L"-Sdklow");
  }
  if (Button_GetCheck(hcleanenv.hWnd) == BST_CHECKED) {
    ea.Append(L"-ClearEnv");
  }
  if (!Execute(ea.data())) {
    auto ec = bela::make_system_error_code();
    bela::BelaMessageBox(m_hWnd, L"CreateProcess failed", ec.message.data(),
                         nullptr, bela::mbs_t::FATAL);
  }
  return S_OK;
}
