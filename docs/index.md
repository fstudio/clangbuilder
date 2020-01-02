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
  "SetWindowCompositionAttribute": false
}
```

+   `EnterpriseWDK` Set EWDK root path and enable Enterprise WDK.
+   `LLVMRoot` Pre-built llvm installation root directory.
+   `LLVMArch` Pre-built llvm default architecture
+   `PwshCoreEnabled` Enable Powershell Core, all script run use pwsh (when you install powershell core).
+   `SetWindowCompositionAttribute` Experimental UI features


## Build Clang on Windows

Clangbuilder Now Only support use Visual C++ build Clang LLVM LLDB.

Best Visual Studio Version:

>Visual Studio 2017 15.9 or later

You can click to run ClangbuilderUI, Modified Arch, Configuration and other options. after click `Building`

**ClangbuilderUI Snapshot**

![clangbuilder](./images/cbui.png)

**ClangbuilderUI EWDK Snapshot**

![ewdk](./images/ewdk.png)

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

You can modify [config/initialize.json](https://github.com/fstudio/clangbuilder/blob/master/config/initialize.json) , add some directories to PATH. Note that directories have **higher priority** in PATH. (Insert Front)


## Suggest

+   Best Platform is Windows 10 x64
+   Select `Use Clean Environment` will reset current process Environment PATH value, Resolve conflict environment variables
+   If your will build lldb, your should install python3.

```powershell
$env:Path = "${env:windir};${env:windir}\System32;${env:windir}\System32\Wbem;${env:windir}\System32\WindowsPowerShell\v1.0"
```
`$evn:windir` is usually `C:\Windows`

## Environment Console

When you only need to start a console environment, you can click on the `Environment Console`.


## Add Portable Utilities

You can port some tools to clangbuilder, see `ports`
and then double-click `script/DevAll.bat` to the software you need as part of the Clangbuilder is added to the environment. Clangbuilder 6.0 support `devi`, You can run devi under `Environment Console`, use `devi install $ToolName` to install your need tools.

Usage:

```txt
devi portable package manager 1.0
Usage: devi cmd tool_name
       list        list installed tools
       search      search ported tools
       install     install tools
       upgrade     upgrade tools
       version     print devi version and exit
       help        print help message
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
ag                  2019-03-23/2.2.0-19-g965f71dA code-searching tool similar to ack, but faster.
aria2               1.34.0              The ultra fast download utility
bat                 v0.11.0             A cat(1) clone with wings.
cmake               3.14.5              CMake is an open-source, cross-platform family of tools designed to build, test and package software
curl                7.65.1_3            Curl is a command-line tool for transferring data specified with URL syntax.
fd                  v7.3.0              A simple, fast and user-friendly alternative to 'find'
git                 2.22.0              Git is a modern distributed version control system focused on speed
hg                  5.0                 Mercurial is a free, distributed source control management tool.
innoextract         1.7                 A tool to unpack installers created by Inno Setup.
innounp             0.48                InnoUnp - Inno Setup Unpacker.
jom                 1.1.3               jom is a clone of nmake
mach2               0.3.0.0             Mach2 manages the Windows Feature Store, where Features (and associated on/off state) live.
nasm                2.14.02             NASM - The Netwide Assembler
neovim              0.3.8               Neovim - Vim-fork focused on extensibility and usability
ninja               1.9.0               Ninja is a small build system with a focus on speed.
nsis                3.04                NSIS (Nullsoft Scriptable Install System) is a professional open source system to create Windows installers.
nuget               5.1.0               NuGet is the package manager for .NET. The NuGet client tools provide the ability to produce and consume packages.
openssh             v8.0.0.0p1-Beta     Portable OpenSSH
perl5               5.30.0.1            Perl 5 is a highly capable, feature-rich programming language.
pijul               0.11.0              Pijul is a free and open source (GPL2) distributed version control system.
putty               0.71                PuTTY: a free SSH and Telnet client.
python3             3.5.4               Python is a programming language.
radare              3.6.0               unix-like reverse engineering framework and commandline tools
ripgrep             11.0.1              ripgrep recursively searches directories for a regex pattern.
swigwin             3.0.12              Simplified Wrapper and Interface Generator
vswhere             2.6.7               Visual Studio Locator.
watchexec           1.10.2              Execute commands in response to file modifications.
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
