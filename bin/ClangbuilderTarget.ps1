#!/usr/bin/env pwsh
param (
    [Parameter(Position = 0)]
    [Alias("id")]
    [String]$InstanceId, # install id
    [String]$InstallationVersion, # installationVersion
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch = "x64",
    [ValidateSet("Release", "Debug", "MinSizeRel", "RelWithDebug")]
    [String]$Flavor = "Release",
    [ValidateSet("MSBuild", "Ninja", "NinjaBootstrap", "NinjaIterate")]
    [String]$Engine = "MSBuild",
    [ValidateSet("Mainline", "Stable", "Release")]
    [String]$Branch = "Mainline", #mainline
    [Alias("e")]
    [Switch]$Environment, # start environment
    [Switch]$Libcxx, # build libcxx if can build
    [Switch]$LLDB,
    [Switch]$LTO,
    [Switch]$Package,
    [Switch]$ClearEnv
)

if ($null -ne "$env:WT_SESSION") {
    $Host.UI.RawUI.WindowTitle = "Clangbuilder 💘 Utility" 
}
else {
    $Host.UI.RawUI.WindowTitle = "Clangbuilder Utility" 
}
 

## Load Profile
."$PSScriptRoot\PreInitialize.ps1"

# Cleanup $env:PATH, because, some tools modify Disrupt PATH
if ($ClearEnv) {
    # ReinitializePath
    ReinitializePath
}

if (Test-Path "$ClangbuilderRoot/config/profile.ps1") {
    ."$ClangbuilderRoot/config/profile.ps1"
}

# Load module
Import-Module -Name "$ClangbuilderRoot\modules\Initialize"
Import-Module -Name "$ClangbuilderRoot\modules\Utils"
Import-Module -Name "$ClangbuilderRoot\modules\CMake"
Import-Module -Name "$ClangbuilderRoot\modules\VisualStudio"
Import-Module -Name "$ClangbuilderRoot\modules\Devi" # Package Manager

$ret = DevinitializeEnv -ClangbuilderRoot $ClangbuilderRoot
if ($ret -ne 0) {
    exit 1
}

# remove curl/ wget alias
if ((Test-Path Alias:curl) -and (Test-Executable "curl.exe")) {
    Remove-Item Alias:curl
}

if ((Test-Path Alias:wget) -and (Test-Executable "wget.exe")) {
    Remove-Item Alias:wget
}

if ($InstanceId.Length -eq 0) {
    $ret = DefaultVisualStudio -ClangbuilderRoot $ClangbuilderRoot -Arch $Arch
}
else {
    $ret = InitializeVisualStudio -ClangbuilderRoot $ClangbuilderRoot -Arch $Arch -InstanceId $InstanceId -InstallationVersion $InstallationVersion
}
if ($InstallationVersion.Length -eq 0) {
    $InstallationVersion = $env:VSENV_VERSION
}

if ($ret -ne 0 -or $InstallationVersion.Length -lt 3) {
    Write-Host -ForegroundColor Red "Not found valid installed visual studio. $InstallationVersion"
    exit 1
}

InitializeExtranl -ClangbuilderRoot $ClangbuilderRoot -Arch $Arch
InitializeEnv -ClangbuilderRoot $ClangbuilderRoot

if ($Environment) {
    Set-Location $ClangbuilderRoot
    return ;
}


if ($null -ne "$env:WT_SESSION") {
    $Host.UI.RawUI.WindowTitle = "Clangbuilder [🛠️: $Branch]" 
}
else {
    $Host.UI.RawUI.WindowTitle = "Clangbuilder [Build: $Branch]" 
}

$ArchTable = @{
    "x86"   = "";
    "x64"   = "Win64";
    "ARM"   = "ARM";
    "ARM64" = "ARM64"
}
$MsvcVersionTable = @{
    "16" = "19.24";
    "15" = "19.16";
    "14" = "19.00";
    "12" = "18.00";
    "11" = "17.00"
};
$ArchName = $ArchTable[$Arch];
$MSBuldGen = ""
if ($ArchName.Length -eq 0) {
    $MSBuldGen = "-G`"Visual Studio $Installation`" "
}
else {
    $MSBuldGen = "-G`"Visual Studio $Installation $ArchName`" "
}
if ([System.Environment]::Is64BitOperatingSystem) {
    $MSBuldGen += "-Thost=x64 ";
}

$Installation = $InstallationVersion.Substring(0, 2)
$msvcversion = "19.20"
try {
    $clexe = (Get-Command -CommandType Application "cl.exe")[0]
    $msvcversion = "$($clexe.FileVersionInfo.FileMajorPart).$($clexe.FileVersionInfo.FileMinorPart)"
}
catch {
    if ($MsvcVersionTable.ContainsKey($Global:Installation)) {
        $msvcversion = $MsvcVersionTable[$Installation]
    }
}

$buildobj = Get-Content -Path "$ClangbuilderRoot/config/build.json" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
# Default build options
$AllowTargets = "X86;AArch64;ARM"
$ExpTargets = "RISCV;WebAssembly"
$Prefix = ""
if ($null -ne $buildobj) {
    if ($null -ne $buildobj.AllowTargets) {
        $AllowTargets = $buildobj.AllowTargets
    }
    if ($null -ne $buildobj.ExpTargets) {
        $ExpTargets = $buildobj.ExpTargets
    }
    if ($null -ne $buildobj.Prefix.$Branch) {
        $Prefix = $buildobj.Prefix.$Branch -replace "\\", "/"
    }
}

Write-Host  "Enable targets: $AllowTargets;$ExpTargets"

# clang;clang-tools-extra;compiler-rt;libcxx;libcxxabi;libunwind;lld;lldb
$AllowProjects = "clang;clang-tools-extra;compiler-rt;lld"
if ($LLDB) {
    $AllowProjects += ";lldb"
}

Function GenCMakeArgs {
    param(
        [Switch]$EnableLIBCXX,
        [Switch]$Bootstrap,
        [String]$ClangDir,
        [String]$SrcDir
    )
    [System.Text.StringBuilder]$ca = New-Object -TypeName System.Text.StringBuilder
    if ($Engine -eq "MSBuild") {
        [void]$ca.Append($MSBuldGen)
        if ($Arch -eq "ARM") {
            [void]$ca.Append("-DCMAKE_C_FLAGS=`"/utf-8 -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1`" ")
            [void]$ca.Append("-DCMAKE_CXX_FLAGS=`"/utf-8 -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1`" ")
        }
        else {
            [void]$ca.Append("-DCMAKE_C_FLAGS=`"/utf-8`" -DCMAKE_CXX_FLAGS=`"/utf-8`" ")
        }
    }
    else {
        [void]$ca.Append("-GNinja ")
    }

    [void]$ca.Append("`"$SrcDir/llvm`" ")
    [void]$ca.Append("-DCMAKE_BUILD_TYPE=$Flavor -DLLVM_ENABLE_ASSERTIONS=OFF ")
    [void]$ca.Append("-DCMAKE_INSTALL_UCRT_LIBRARIES=ON ")

    if ($Bootstrap) {
        [void]$ca.Append("-DLLVM_ENABLE_PROJECTS=`"clang;lld`" ")
        [void]$ca.Append("-DLLVM_TARGETS_TO_BUILD=`"X86;AArch64`" ")
        [void]$ca.Append("-DCMAKE_C_FLAGS=`"-utf-8`" -DCMAKE_CXX_FLAGS=`"-utf-8`" ")
    }
    else {
        [void]$ca.Append("-DLLVM_TARGETS_TO_BUILD=`"$AllowTargets`" ")
        [void]$ca.Append("-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=`"$ExpTargets`" ")
        if ($EnableLIBCXX) {
            [void]$ca.Append("-DLLVM_ENABLE_PROJECTS=`"$AllowProjects;libcxx`" ")
            [void]$ca.Append("-DLLVM_FORCE_BUILD_RUNTIME=ON -DLIBCXX_ENABLE_SHARED=YES ")
            [void]$ca.Append("-DLIBCXX_ENABLE_STATIC=YES -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=NO ")
            [void]$ca.Append("-DLIBCXX_HAS_WIN32_THREAD_API=ON -DLIBCXX_STANDARD_VER=`"c++17`" ")
        }
        else {
            [void]$ca.Append("-DLLVM_ENABLE_PROJECTS=`"$AllowProjects`" ")
        }
    }

    if (![String]::IsNullOrEmpty($Prefix)) {
        [void]$ca.Append("-DCMAKE_INSTALL_PREFIX=`"$Prefix`" ")
    }
    if ($LLDB -and !$Bootstrap) {
        [void]$ca.Append("-DLLDB_RELOCATABLE_PYTHON=1 -DLLDB_DISABLE_PYTHON=1 ")
    }
    if (![String]::IsNullOrEmpty($ClangDir) -and (Test-Path $ClangDir)) {
        $ClangDir = $ClangDir.Replace("\", "/")
        # Force Enable clang-cl
        [void]$ca.Append("-DCMAKE_C_COMPILER=`"$ClangDir/clang-cl.exe`" -DCMAKE_CXX_COMPILER=`"$ClangDir/clang-cl.exe`" ")
        $archtable = @{
            "x64"   = "-m64";
            "x86"   = "-m32";
            "ARM"   = "--target=arm-pc-windows-msvc -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1";
            "ARM64" = "--target=arm64-pc-windows-msvc -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1"
        }
        $curarch = $archtable[$Arch]
        $ccxxflags = "-fms-compatibility-version=$msvcversion $curarch "
        Write-Host "Detecting: $ccxxflags "
        #$cxxstd="-std:c++17 -Zc:__cplusplus -permissive-"
        #[void]$ca.Append("-DCLANG_DEFAULT_STD_CXX=cxx17 -DLLVM_ENABLE_CXX1Z=ON -DLLVM_CXX_STD=`"c++17`" ")
        [void]$ca.Append("-DCMAKE_CXX_FLAGS=`"$ccxxflags $cxxstd`" ")
        [void]$ca.Append("-DCMAKE_C_FLAGS=`"$ccxxflags`" ")
        if ($LTO) {
            # LLVM LTO
            [void]$ca.Append("-DLLVM_ENABLE_LTO=Thin ")
            [void]$ca.Append("-DCMAKE_LINKER=`"$ClangDir/lld-link.exe`" ")
            # llvm-lib is a alias for llvm-ar
            [void]$ca.Append("-DCMAKE_AR=`"$ClangDir/llvm-lib.exe`" ")
            [void]$ca.Append("-DCMAKE_RANLIB=`"$ClangDir/llvm-ranlib.exe`"")
        }
    }
    return $ca.ToString()
};


Function GetLLVM {
    param(
        [string]$Branch,
        [string]$OutDir
    )
    $cloneargs = "clone https://github.com/llvm/llvm-project.git --branch `"$Branch`" --single-branch --depth=1 `"$OutDir`""
    if (Test-Path $OutDir) {
        $ex = ProcessExec -FilePath "git" -Argv "checkout ." -WD "$OutDir"
        if ($ex -ne 0) {
            return $ex
        }
        $ex = ProcessExec  -FilePath "git" -Argv "pull" -WD "$OutDir"
        return $ex
    }
    return  ProcessExec -FilePath "git" -Argv "$cloneargs" 
}

$llvmout = "$ClangbuilderRoot/out" -replace "\\", "/"
New-Item -ItemType Directory -Path $llvmout  -Force -ErrorAction SilentlyContinue | Out-Null

$revobj = Get-Content -Path "$ClangbuilderRoot/config/llvm.json" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
if ($null -eq $revobj -or ($null -eq $revobj.Stable)) {
    Write-Host -ForegroundColor Red "version.json format is incorrect"
    exit 1
}

[char]$Esc = 0x1B
[string]$stable = $revobj.Stable
[string]$release = $revobj.Release
[string]$releaseurl = $revobj.ReleaseUrl
[string]$MV = $revobj.Mainline
[string]$releasedir = "llvmorg-$release"

Write-Host "LLVM master version $Esc[1;32m$MV$Esc[0m. stable branch is $Esc[1;32m$stable$Esc[0m. latest release is: $Esc[1;32m$release$Esc[0m
Your select to build '$Esc[1;32m$Branch$Esc[0m' mode
The prefix you chose is: $Esc[1;33m$Prefix$Esc[0m"


$sourcedir = "$llvmout/mainline"
if ($Branch -eq "Stable") {
    $s1 = $stable -replace "(\\|\/)", "_"
    $sourcedir = "$llvmout/$s1"
    $ex = GetLLVM -Branch $stable -OutDir $sourcedir
    if ($ex -ne 0) {
        exit $ex
    }
}
elseif ($Branch -eq "Release") {
    $curlcliv = Get-COmmand -CommandType Application -ErrorAction SilentlyContinue "curl"
    if ($null -eq $curlcliv) {
        Write-Host -ForegroundColor "Please install curl to allow download llvm"
        exit 1
    }
    $curlcli = $curlcliv[0].Source
    $outfile = "$releasedir.tar.gz"
    Write-Host "Download file: $outfile"
    $ex = ProcessExec -FilePath "$curlcli" -Argv "--progress-bar -fS --connect-timeout 15 --retry 3 -o `"$outfile`" -L --proto-redir =https $releaseurl" -WD $llvmout
    if ($ex -ne 0) {
        exit 1
    }
    tar -xvf "$outfile"
    $sourcedir = "$llvmout/$releasedir"
}
else {
    $ex = GetLLVM -Branch "master" -OutDir $sourcedir
    if ($ex -ne 0) {
        exit $ex
    }
}

if ($Engine -eq "MSBuild") {
    $cmakeargs = GenCMakeArgs -SrcDir $sourcedir
    Remove-Item  "$llvmout/msbuild"  -Force -Recurse -ErrorAction SilentlyContinue
    New-Item -ItemType Directory "$llvmout/msbuild" | Out-Null
    $ec = ProcessExec -FilePath "cmake" -Argv "$cmakeargs" -WD "$llvmout/msbuild"
    if ($ec -ne 0) {
        exit $ec
    }
    $ec = ProcessExec -FilePath "cmake" -Argv "--build . --config $Flavor" -WD "$llvmout/msbuild"
    if ($ec -ne 0) {
        exit $ec
    }
    if (!$Package) {
        return 
    }
    if (Test-Path "$llvmout/msbuild/LLVM.sln") {
        CMakeInstallationFix -TargetDir "$llvmout/msbuild/projects/compiler-rt/lib" -Configuration $Flavor
    }
    $ec = ProcessExec -FilePath "cpack" -Argv "-C $Flavor" -WD "$llvmout/msbuild"
    if ($ec -ne 0) {
        exit $ec
    }
    return 
}

if ($Engine -eq "Ninja" -or $Engine -eq "NinjaBootstrap") {
    $cmakeargs = GenCMakeArgs -SrcDir $sourcedir
    if ($Engine -eq "NinjaBootstrap") {
        $cmakeargs = GenCMakeArgs -SrcDir $sourcedir -Bootstrap
    }
    Remove-Item "$llvmout/msvcninja" -Force -Recurse -ErrorAction SilentlyContinue
    New-Item -ItemType Directory "$llvmout/msvcninja" | Out-Null
    $ec = ProcessExec -FilePath "cmake" -Argv "$cmakeargs" -WD "$llvmout/msvcninja"
    if ($ec -ne 0) {
        exit $ec
    }
    $PN = & Parallel
    $ec = ProcessExec -FilePath "ninja" -Argv "all -j $PN" -WD "$llvmout/msvcninja"
    if ($ec -ne 0) {
        exit $ec
    }
    if ($Package -and ($Engine -ne "NinjaBootstrap")) {
        $ec = ProcessExec -FilePath "cpack" -Argv "-C $Flavor" -WD "$llvmout/msvcninja"
        if ($ec -ne 0) {
            exit $ec
        }
        return 
    }
    if ($Engine -ne "NinjaBootstrap") {
        return 
    }
}

$ClangDir = ""
if ($Engine -eq "NinjaBootstrap") {
    $ClangDir = "$llvmout/msvcninja/bin"
}
elseif ($Engine -eq "NinjaIterate") {
    $llvmobj = Get-Content -Path "$ClangbuilderRoot/config/settings.json" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($null -eq $llvmobj.LLVMRoot) {
        Write-Host -ForegroundColor Red "Please set your clang install prefix"
        exit 1
    }
    $ClangDir = (Join-Path $llvmobj.LLVMRoot "bin") -replace "\\", "/"
}

if ([String]::IsNullOrEmpty($ClangDir)) {
    Write-Host -ForegroundColor Red "Please set your clang install prefix"
    exit 1
}

$cmakeargs = GenCMakeArgs -ClangDir $ClangDir -EnableLIBCXX:$Libcxx -SrcDir $sourcedir


Remove-Item -Force -Recurse "$llvmout/clangninja" -ErrorAction SilentlyContinue
New-Item -ItemType Directory "$llvmout/clangninja" | Out-Null

$ec = ProcessExec -FilePath "cmake" -Argv "$cmakeargs" -WD "$llvmout/clangninja"
if ($ec -ne 0) {
    exit $ec
}
$PN = & Parallel
$ec = ProcessExec -FilePath "ninja" -Argv "all -j $PN" -WD "$llvmout/clangninja"
if ($ec -ne 0) {
    exit $ec
}

#$Libcxxbin = "$llvmout/clangninja/lib/c++.dll"
#$CMakeInstallFile = "$llvmout/clangninja/cmake_install.cmake"
#if (Test-Path $Libcxxbin) {
#    "file(INSTALL DESTINATION `"`${CMAKE_INSTALL_PREFIX}/bin`" TYPE SHARED_LIBRARY OPTIONAL FILES `"$Libcxxbin`")" | Out-File -FilePath $CMakeInstallFile -Append -Encoding utf8
#}

if ($Package ) {
    $ec = ProcessExec -FilePath "cpack" -Argv "-C $Flavor" -WD "$llvmout/clangninja"
    if ($ec -ne 0) {
        exit $ec
    }
}

Write-Host "compile llvm done, you can use it"

