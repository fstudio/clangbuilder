///////
#include "inc/apphelp.hpp"
#include "inc/apputils.hpp"
#include <windowsx.h>
#include "appui.hpp"

bool PsCreateProcess(LPWSTR pszCommand) {
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
  if (CreateProcessW(nullptr, pszCommand, NULL, NULL, FALSE,
                     CREATE_NEW_CONSOLE | NORMAL_PRIORITY_CLASS, NULL, NULL,
                     &si, &pi)) {
    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
    return true;
  }
  return false;
}

LPWSTR FormatMessageInternal() {
  LPWSTR hlocal;
  if (FormatMessageW(
          FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS |
              FORMAT_MESSAGE_ALLOCATE_BUFFER,
          NULL, GetLastError(), MAKELANGID(LANG_NEUTRAL, SUBLANG_NEUTRAL),
          (LPWSTR)&hlocal, 0, NULL)) {
    return hlocal;
  }
  return nullptr;
}

LRESULT MainWindow::OnBuildNow(WORD wNotifyCode, WORD wID, HWND hWndCtl,
                               BOOL &bHandled) {
  std::wstring Command;
  if (!clangbuilder::IsPwshCoreEnable(root, Command)) {
    if (!clangbuilder::LookupPwshDesktop(Command)) {
      utils::PrivMessageBox(m_hWnd, L"PowerShell not found",
                            L"Please check PowerShell is installed", nullptr,
                            utils::kFatalWindow);
      return S_FALSE;
    }
  }

  Command.append(L" -NoLogo -NoExit   -File \"")
      .append(targetFile)
      .push_back('"');
  auto vsindex_ = ComboBox_GetCurSel(hVisualStudioBox);
  if (vsindex_ < 0 || instances_.size() <= (size_t)vsindex_) {
    return S_FALSE;
  }
  auto archindex_ = ComboBox_GetCurSel(hPlatformBox);
  if (archindex_ < 0 || tables.Targets.size() <= archindex_) {
    return S_FALSE;
  }
  int xver = 0;
  wchar_t *mm = nullptr;
  xver = wcstoul(instances_[vsindex_].installversion.c_str(), &mm, 10);
  if (xver < 15 && archindex_ >= 3) {
    utils::PrivMessageBox(
        m_hWnd, L"This toolchain does not support ARM64",
        L"Please use Visual Studio 15.4 or Later (CppDailyTools "
        L"14.13.26310 or Later)",
        nullptr, utils::kFatalWindow);
    return S_FALSE;
  }
  auto flavor_ = ComboBox_GetCurSel(hConfigBox);
  if (flavor_ < 0 || tables.Configurations.size() <= flavor_) {
    return S_FALSE;
  }

  auto be = ComboBox_GetCurSel(hBuildBox);
  if (be < 0 || tables.Engines.size() <= be) {
    return S_FALSE;
  }

  auto bs = ComboBox_GetCurSel(hBranchBox);
  if (bs < 0 || tables.Branches.size() <= bs) {
    return S_FALSE;
  }

  Command.append(L" -InstanceId ").append(instances_[vsindex_].instanceId);
  Command.append(L" -InstallationVersion ")
      .append(instances_[vsindex_].installversion);
  Command.append(L" -Arch ").append(tables.Targets[archindex_]);
  Command.append(L" -Flavor ").append(tables.Configurations[flavor_]);
  Command.append(L" -Engine ").append(tables.Engines[be].Value);
  Command.append(L" -Branch ").append(tables.Branches[bs]);

  if ((be == 1 || be == 3) && Button_GetCheck(hLibcxx_) == BST_CHECKED) {
    Command.append(L" -Libcxx");
  }

  if (Button_GetCheck(hCheckLTO_) == BST_CHECKED) {
    Command.append(L" -LTO");
  }

  if (Button_GetCheck(hCheckSdklow_) == BST_CHECKED) {
    Command.append(L" -Sdklow");
  }

  if (Button_GetCheck(hCheckPackaged_) == BST_CHECKED) {
    Command.append(L" -Package");
  }

  if (Button_GetCheck(hCheckLLDB_) == BST_CHECKED) {
    Command.append(L" -LLDB");
  }

  if (Button_GetCheck(hCheckCleanEnv_) == BST_CHECKED) {
    Command.append(L" -ClearEnv");
  }
  if (!PsCreateProcess(&Command[0])) {
    ////
    auto errmsg = FormatMessageInternal();
    if (errmsg) {
      utils::PrivMessageBox(m_hWnd, L"CreateProcess failed", errmsg, nullptr,
                            utils::kFatalWindow);
      LocalFree(errmsg);
    }
  }
  return S_OK;
}

LRESULT MainWindow::OnStartupEnv(WORD wNotifyCode, WORD wID, HWND hWndCtl,
                                 BOOL &bHandled) {
  std::wstring Command;
  if (!clangbuilder::IsPwshCoreEnable(root, Command)) {
    if (!clangbuilder::LookupPwshDesktop(Command)) {
      utils::PrivMessageBox(m_hWnd, L"Search PowerShell Error",
                            L"Please check PowerShell", nullptr,
                            utils::kFatalWindow);
      return S_FALSE;
    }
  }

  Command.append(L" -NoLogo -NoExit   -File \"")
      .append(targetFile)
      .push_back('"');
  auto vsindex_ = ComboBox_GetCurSel(hVisualStudioBox);
  if (vsindex_ < 0 || instances_.size() <= (size_t)vsindex_) {
    return S_FALSE;
  }
  auto archindex_ = ComboBox_GetCurSel(hPlatformBox);
  if (archindex_ < 0 || tables.Targets.size() <= archindex_) {
    return S_FALSE;
  }
  int xver = 0;
  wchar_t *mm = nullptr;
  xver = wcstoul(instances_[vsindex_].installversion.c_str(), &mm, 10);
  if (xver < 15 && archindex_ >= 3) {
    utils::PrivMessageBox(
        m_hWnd, L"This toolchain does not support ARM64",
        L"Please use Visual Studio 15.4 or Later (CppDailyTools "
        L"14.13.26310 or Later)",
        nullptr, utils::kFatalWindow);
    return S_FALSE;
  }
  Command.append(L" -Environment -InstanceId ")
      .append(instances_[vsindex_].instanceId);
  Command.append(L" -InstallationVersion ")
      .append(instances_[vsindex_].installversion);
  Command.append(L" -Arch ").append(tables.Targets[archindex_]);
  if (Button_GetCheck(hCheckSdklow_) == BST_CHECKED) {
    Command.append(L" -Sdklow");
  }
  if (Button_GetCheck(hCheckCleanEnv_) == BST_CHECKED) {
    Command.append(L" -ClearEnv");
  }

  if (!PsCreateProcess(&Command[0])) {
    auto errmsg = FormatMessageInternal();
    if (errmsg) {
      utils::PrivMessageBox(m_hWnd, L"CreateProcess failed", errmsg, nullptr,
                            utils::kFatalWindow);
      LocalFree(errmsg);
    }
  }
  return S_OK;
}
