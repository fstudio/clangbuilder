////////////
#ifndef CBUI_VERSION_HPP
#define CBUI_VERSION_HPP

#ifdef APPVEYOR_BUILD_NUMBER
#define CLANGBUILDER_BUILD_NUMBER APPVEYOR_BUILD_NUMBER
#else
#define CLANGBUILDER_BUILD_NUMBER 1
#endif

#define TOSTR_1(x) L#x
#define TOSTR(x) TOSTR_1(x)

#define CLANGBUILDERSUBVER TOSTR(CLANGBUILDER_BUILD_NUMBER)

#define CLANGBUILDER_MAJOR_VERSION 7
#define CLANGBUILDER_MINOR_VERSION 0
#define CLANGBUILDER_PATCH_VERSION 0

#define CLANGBUILDER_MAJOR TOSTR(CLANGBUILDER_MAJOR_VERSION)
#define CLANGBUILDER_MINOR TOSTR(CLANGBUILDER_MINOR_VERSION)
#define CLANGBUILDER_PATCH TOSTR(CLANGBUILDER_PATCH_VERSION)

#define CLANGBUILDER_VERSION_MAIN CLANGBUILDER_MAJOR L"." CLANGBUILDER_MINOR
#define CLANGBUILDER_VERSION_FULL                                              \
  CLANGBUILDER_VERSION_MAIN L"." CLANGBUILDER_PATCH

#ifdef APPVEYOR_BUILD_NUMBER
#define CLANGBUILDER_BUILD_VERSION                                             \
  CLANGBUILDER_VERSION_FULL L"." CLANGBUILDERSUBVER L" (appveyor)"
#else
#define CLANGBUILDER_BUILD_VERSION                                             \
  CLANGBUILDER_VERSION_FULL L"." CLANGBUILDERSUBVER L" (dev)"
#endif

#define CLANGBUILDER_APPLINK                                                   \
  L"For more information about this tool. \nVisit: <a "                        \
  L"href=\"https://github.com/fstudio/clangbuilder\">Clangbuilder</"           \
  L"a>\nVisit: <a "                                                            \
  L"href=\"https://forcemz.net/\">forcemz.net</a>"

#define CLANGBUILDER_APPLINKE                                                  \
  L"Ask for help with this issue. \nVisit: <a "                                \
  L"href=\"https://github.com/fstudio/clangbuilder/issues\">Clangbuilder "     \
  L"Issues</a>"

#define CLANGBUILDER_APPVERSION                                                \
  L"Version: " CLANGBUILDER_VERSION_FULL L"\nCopyright \xA9 2020, Force "      \
  L"Charlie. All Rights Reserved."

#define CLANGBUILDERUI_COPYRIGHT                                               \
  L"\nCopyright \xA9 2020, Force Charlie. All Rights Reserved."

#endif
