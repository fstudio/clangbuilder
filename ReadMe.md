# Clangbuilder

<a href="LICENSE"><img src="https://img.shields.io/github/license/fstudio/clangbuilder.svg"></a>
<a href="https://996.icu"><img src="https://img.shields.io/badge/link-996.icu-red.svg"></a>

Automated tools help developers on Windows platforms building LLVM and clang.

## Installation

Clone clangbuilder on Github

```shell
git clone https://github.com/fstudio/clangbuilder.git clangbuilder
```

Click the `script/InitializeEnv.bat`

The installation script will compile ClangbuilderUI and create a shortcut, download required packages.

## Settings

Your can modified settings.json to change your clangbuilder run mode. `settings.template.json` content like here:

```json
{
  "EnterpriseWDK": "D:\\EWDK",
  "LLVMRoot": "D:\\LLVM",
  "LLVMArch": "x64",
  "PwshCoreEnabled": true,
  "UseWindowsTerminal": true,
  "Conhost": "C:\\Path\\To\\OpenConsole.exe",
  "SetWindowCompositionAttribute": false
}
```

+   `EnterpriseWDK` Set EWDK root path and enable Enterprise WDK.
+   `LLVMRoot` Pre-built llvm installation root directory.
+   `LLVMArch` Pre-built llvm default architecture
+   `PwshCoreEnabled` Enable Powershell Core, all script run use pwsh (when you install powershell core).
+   `UseWindowsTerminal` Use Windows Terminal (We need wt support commandline)
+   `Conhost` If Windows Termianl not exists, your can set OpenConsole path.
+   `SetWindowCompositionAttribute` Fluent UI features


## Build Clang on Windows

Clangbuilder Now Only support use Visual C++ build Clang LLVM LLDB.

Best Visual Studio Version:

>Visual Studio 2019 16.3 or later

You can click to run ClangbuilderUI, Modified Arch, Configuration and other options. after click `Building`

**ClangbuilderUI Snapshot**

![clangbuilder](./docs/images/cbui.png)

**Branch**

+   Mainline, master/trunk branch , git fetch from [https://github.com/llvm-mirror/](https://github.com/llvm-mirror/)
+   Stable, llvm stable branch, like release_80, git fetch from [https://github.com/llvm-mirror/](https://github.com/llvm-mirror/)
+   Release, llvm release tag, download for [https://releases.llvm.org/](https://releases.llvm.org/)


**CMake Custom flags**

You can custom cmake build flags Now !!!

Clangbuilder will check `$ClangbuilderRoot\out\cmakeflags.$Branch.json` and `$ClangbuilderRoot\out\cmakeflags.json` is exists, if exists parse cmake flags.

The corresponding branch takes effect:

```txt
cmakeflags.mainline.json
cmakeflags.stable.json
cmakeflags.release.json
```

Set `cmakeflags.json` will take effect in all branches (Mainline, Stable, Release)

Flags configuration format is json:

```json
{
    "CMake":[
        "-DCMAKE_INSTALL_PREFIX=\"D:/LLVM\""
    ]
}
```

**Engine**

+   MSbuild use msbuild build llvm `MSBuild - MSVC`
+   Ninja use ninja build llvm `Ninja - MSVC`
+   NinjaBootstrap use ninja build and bootstrap llvm `Ninja - Bootstrap`
+   NinjaIterate use ninja build llvm, but compile is prebuilt clang (config by `config\prebuilt.json`) `Ninja - Clang`

**LLDB**

When you select build LLDB, If not found Python 3 installed. Clangbuilder add flag `-DLLDB_DISABLE_PYTHON=1`.

LLDB maybe not work.

**Libc++**

Only NinjaBootstrap and NinjaIterate will compile libc++ ,Because Visual C++ not support `include_next` now.

```powershell
clang-cl -std:c++14  -Iinclude\c++\v1 hello.cc c++.lib
```

after copy `c++.dll` to your path(or exe self directory).

**Use Clean Environment**

Clangbuilder support `Clean Environment`, When use `-ClearEnv` flag or enable check box `Use Clean Environment`, Clangbuilder will retset `$env:PATH`.

```powershell
Function ReinitializePath {
    if ($PSEdition -eq "Desktop" -or $IsWindows) {
        $env:PATH += "${env:windir};${env:windir}\System32;${env:windir}\System32\Wbem;${env:windir}\System32\WindowsPowerShell\v1.0"
    }
    else {
        $env:PATH = "/usr/local/bin:/usr/bin:/bin"
    }
}

```

## Custom PATH

You can modify [config/initialize.json](./config/initialize.json) , add some directories to PATH. Note that directories have **higher priority** in PATH. (Insert Front)


## Suggest

+   Best Platform is Windows 10 x64
+   Select `Use Clean Environment` will reset current process Environment PATH value, Resolve conflict environment variables
+   If your will build lldb, your should install python3.

```powershell
$env:Path = "${env:windir};${env:windir}\System32;${env:windir}\System32\Wbem;${env:windir}\System32\WindowsPowerShell\v1.0"
```
`$evn:windir` is usually `C:\Windows`

## Windows Terminal/Windows Console

When you only need to start a console environment, you can click on the `Windows Terminal`/`Windows Console`.


## Add Portable Utilities

You can port some tools to clangbuilder, see `ports`
and then double-click `script/DevAll.bat` to the software you need as part of the Clangbuilder is added to the environment. Clangbuilder 6.0 support `devi`, You can run devi under `Environment Console`, use `devi install $ToolName` to install your need tools.

Usage:

```txt
devi 7.0 portable package manager
Usage: devi cmd package-name
    list         list installed package
    search       search ported package
    install      install package
    uninstall    uninstall package
    upgrade      upgrade all upgradeable packages
    help         print help message
    version      print devi version and exit
```

Default installed tools:

```json
{
    "core": [
        "7z",
        "cmake",
        "git",
        "ninja",
        "nsis",
        "nuget",
        "python2",
        "vswhere"
    ]
}
```

Current ported tools:

```txt
7z                  19.00               7-Zip is a file archiver with a high compression ratio
ag                  2019-03-23/2.2....  A code-searching tool similar to ack, but faster.
arc                 3.2                 Introducing Archiver - a cross-platform, multi-format archive utility
aria2               1.35.0              The ultra fast download utility
bat                 v0.12.1             A cat(1) clone with wings.
cmake               3.16.4              CMake is an open-source, cross-platform family of tools designed to build, test and package software
curl                7.68.0              Curl is a command-line tool for transferring data specified with URL syntax.
dmd                 2.090.0             D is a general-purpose programming language with static typing, systems-level access, and C-like syntax
fd                  v7.4.0              A simple, fast and user-friendly alternative to 'find'
git                 2.25.0              Git is a modern distributed version control system focused on speed
hg                  5.3                 Mercurial is a free, distributed source control management tool.
innoextract         1.8                 A tool to unpack installers created by Inno Setup.
innounp             0.49                InnoUnp - Inno Setup Unpacker.
jom                 1.1.3               jom is a clone of nmake
mach2               0.3.0.0             Mach2 manages the Windows Feature Store, where Features (and associated on/off state) live.
nasm                2.14.02             NASM - The Netwide Assembler
neovim              0.4.2               Neovim - Vim-fork focused on extensibility and usability
ninja               1.10.0              Ninja is a small build system with a focus on speed.
nsis                3.05                NSIS (Nullsoft Scriptable Install System) is a professional open source system to create Windows installers.
nuget               5.4.0               NuGet is the package manager for .NET. The NuGet client tools provide the ability to produce and consume packages.
openssh             v8.1.0.0p1-Beta     Portable OpenSSH
perl5               5.30.0.1            Perl 5 is a highly capable, feature-rich programming language.
pijul               0.11.0              Pijul is a free and open source (GPL2) distributed version control system.
putty               0.73                PuTTY: a free SSH and Telnet client.
python3             3.5.4               Python is a programming language.
radare              4.0.0               unix-like reverse engineering framework and commandline tools
ripgrep             11.0.2              ripgrep recursively searches directories for a regex pattern.
shfmt               3.0.1               A shell formatter.
swigwin             4.0.1               Simplified Wrapper and Interface Generator
unrar               5.90                Decompress RAR files.
vswhere             2.8.4               Visual Studio Locator.
watchexec           1.11.1              Execute commands in response to file modifications.
wget                1.20.3              A command-line utility for retrieving files using HTTP, HTTPS and FTP protocols.
```

**Extensions**:

We support 4 extensions: `exe`, `zip`, `msi`, `7z`. If 7z is not installed, only the first three extensions are supported. If you need to port a 7z extension type of package, you need to understand the decompression format supported by 7z.exe.

>7z.exe supported formats(Unpacking): AR, ARJ, CAB, CHM, CPIO, CramFS, DMG, EXT, FAT, GPT, HFS, IHEX, ISO, LZH, LZMA, MBR, MSI, NSIS, NTFS, QCOW2, RAR, RPM, SquashFS, UDF, UEFI, VDI, VHD, VMDK, WIM, XAR and Z




## Add Extranl Libs

You can add extranl lib, such as [z3](https://github.com/Z3Prover/z3),
download extranl lib, unpack to `bin/external` , `bin/external/include` is include dir, `bin/external/lib/$arch(x86,x64,arm,arm64)`, `bin/external/bin/$arch(x86,x64,arm,arm64)`.

## About Ninja Task

**Ninja Task Parallel:**

```powershell
Function Parallel() {
    $MemSize = (Get-CimInstance -Class Win32_ComputerSystem).TotalPhysicalMemory
    $ProcessorCount = $env:NUMBER_OF_PROCESSORS
    $MemParallelRaw = $MemSize / 1610612736 #1.5GB
    #[int]$MemParallel = [Math]::Floor($MemParallelRaw)
    [int]$MemParallel = [Math]::Ceiling($MemParallelRaw) ## less 1
    return [Math]::Min($ProcessorCount, $MemParallel)
}
```

## Copyright

License: MIT  
Author: Force.Charlie  
Copyright © 2020 Force Charlie. All Rights Reserved.
