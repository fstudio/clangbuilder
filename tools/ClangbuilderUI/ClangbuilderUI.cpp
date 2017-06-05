// ClangbuilderUI.cpp : Defines the entry point for the application.
//

#include "stdafx.h"
#include "ClangbuilderUI.h"
#include "Clangbuilder.h"
#include "MainWindow.h"

class DotComInitialize {
public:
  DotComInitialize() {
    if (FAILED(CoInitialize(NULL))) {
      throw std::runtime_error("CoInitialize failed");
    }
  }
  ~DotComInitialize() { CoUninitialize(); }
};

int WindowMessageRunLoop() {
  INITCOMMONCONTROLSEX info = {sizeof(INITCOMMONCONTROLSEX),
                               ICC_TREEVIEW_CLASSES | ICC_COOL_CLASSES |
                                   ICC_LISTVIEW_CLASSES};
  InitCommonControlsEx(&info);
  MainWindow window;
  MSG msg;
  window.InitializeWindow();
  window.ShowWindow(SW_SHOW);
  window.UpdateWindow();
  while (GetMessage(&msg, nullptr, 0, 0) > 0) {
    TranslateMessage(&msg);
    DispatchMessage(&msg);
  }
  return 0;
}

int APIENTRY _tWinMain(_In_ HINSTANCE hInstance,
                       _In_opt_ HINSTANCE hPrevInstance, _In_ LPTSTR lpCmdLine,
                       _In_ int nCmdShow) {
  UNREFERENCED_PARAMETER(hPrevInstance);
  UNREFERENCED_PARAMETER(lpCmdLine);
  UNREFERENCED_PARAMETER(nCmdShow);
  UNREFERENCED_PARAMETER(hInstance);
  DotComInitialize dot;
  HeapSetInformation(NULL, HeapEnableTerminationOnCorruption, NULL, 0);
  return WindowMessageRunLoop();
}
