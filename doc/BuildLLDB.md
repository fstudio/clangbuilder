# BUILDING LLDB ON WINDOWS    
## Required Dependencies     

- Visual Studio 2015 or greater    
- Windows SDK 8.0 or higher. In general it is best to use the latest available version.   
- [Python 3.5](https://www.python.org/downloads/windows/) or higher or higher. Earlier versions of Python can be made to work by compiling your own distribution from source, but this workflow is unsupported and you are own your own.
- [Ninja build tool](http://martine.github.io/ninja/) (strongly recommended)
- [GnuWin32](http://gnuwin32.sourceforge.net/)
- [SWIG for Windows (version 3+)](http://www.swig.org/download.html)

## Optional Dependencies

- [Python Tools for Visual Studio](https://github.com/Microsoft/PTVS/releases). If you plan to debug test failures or even write new tests at all, PTVS is an indispensable debugging extension to VS that enables full editing and debugging support for Python (including mixed native/managed debugging)

## Preliminaries

This section describes how to set up your system and install the required dependencies such that they can be found when needed during the build process. The steps outlined here only need to be performed once.


1. Install Visual Studio and the Windows SDK.

2. Install GnuWin32, making sure <GnuWin32 install dir>\bin is added to your PATH environment variable.

3. Install SWIG for Windows, making sure <SWIG install dir> is added to your PATH environment variable.

## Building LLDB

Any command prompt from which you build LLDB should have a valid Visual Studio environment setup. This means you should run vcvarsall.bat or open an appropriate Visual Studio Command Prompt corresponding to the version you wish to use.

Finally, when you are ready to build LLDB, generate CMake with the following command line:

cmake -G Ninja <cmake variables> <path to root of llvm src tree>
and run ninja to build LLDB. Information about running the LLDB test suite can be found on the test page.

Following is a description of some of the most important CMake variables which you are likely to encounter. A variable FOO is set by adding -DFOO=value to the CMake command line.

- LLDB_TEST_DEBUG_TEST_CRASHES (Default=0): If set to 1, will cause Windows to generate a crash dialog whenever lldb.exe or the python extension module crashes while running the test suite. If set to 0, LLDB will silently crash. Setting to 1 allows a developer to attach a JIT debugger at the time of a crash, rather than having to reproduce a failure or use a crash dump.
- PYTHON_HOME (Required): Path to the folder where the Python distribution is installed. For example, C:\Python35
- LLDB_RELOCATABLE_PYTHON (Default=0): When this is 0, LLDB will bind statically to the location specified in the PYTHON_HOME CMake variable, ignoring any value of PYTHONHOME set in the environment. This is most useful for developers who simply want to run LLDB after they build it. If you wish to move a build of LLDB to a different machine where Python will be in a different location, setting LLDB_RELOCATABLE_PYTHON to 1 will cause Python to use its default mechanism for finding the python installation at runtime (looking for installed Pythons, or using the PYTHONHOME environment variable if it is specified).
- LLDB_TEST_COMPILER: The test suite needs to be able to find a copy of clang.exe that it can use to compile inferior programs. Note that MSVC is not supported here, it must be a path to a clang executable. Note that using a release clang.exe is strongly recommended here, as it will make the test suite run much faster. This can be a path to any recent clang.exe, including one you built yourself.
Sample command line:
```batch
cmake -G Ninja -DLLDB_TEST_DEBUG_TEST_CRASHES=1 -DPYTHON_HOME=C:\Python35 -DLLDB_TEST_COMPILER=d:\src\llvmbuild\ninja_release\bin\clang.exe ..\..\llvm
```

Working with both Ninja and MSVC

Compiling with ninja is both faster and simpler than compiling with MSVC, but chances are you still want to debug LLDB with MSVC (at least until we can debug LLDB on Windows with LLDB!). One solution to this is to run cmake twice and generate the output into two different folders. One for compiling (the ninja folder), and one for editing / browsing / debugging (the MSVC folder).

To do this, simply run `cmake -G Ninja <arguments>` from one folder, and `cmake -G "Visual Studio 14 2015" <arguments>` in another folder. Then you can open the .sln file in Visual Studio, set lldb as the startup project, and use F5 to run it. You need only edit the project settings to set the executable and the working directory to point to binaries inside of the ninja tree.