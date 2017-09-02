#!/usr/bin/env powershell
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch = "x64",
    [ValidateSet("Release", "Debug", "MinSizeRel", "RelWithDebug")]
    [String]$Flavor = "Release",
    [ValidateSet("MSBuild", "Ninja", "NinjaBootstrap", "NinjaIterate")]
    [String]$Engine = "MSBuild",
    [ValidateSet("Mainline", "Stable", "Release")]
    [String]$Branch = "Mainline", #mainline 
    [String]$InstanceId, # install id
    [String]$InstallationVersion, # installationVersion
    [Switch]$Environment, # start environment 
    [Switch]$Sdklow, # low sdk support
    [Switch]$LLDB,
    [Switch]$Static,
    [Switch]$Package,
    [Switch]$ClearEnv
)

$Global:ClangbuilderRoot = Split-Path -Parent $PSScriptRoot

Import-Module -Name "$Global:ClangbuilderRoot\modules\Initialize"
Import-Module -Name "$Global:ClangbuilderRoot\modules\Utils"
Import-Module -Name "$Global:ClangbuilderRoot\modules\CMake"
Import-Module -Name "$Global:ClangbuilderRoot\modules\VisualStudio"
Import-Module -Name "$Global:ClangbuilderRoot\modules\PM" # Package Manager


#

if ($ClearEnv) {
    # ReinitializePath
    ReinitializePath
}

InitializeEnv -ClangbuilderRoot $ClangbuilderRoot
InitializePackageEnv -ClangbuilderRoot $ClangbuilderRoot
InitializeVisualStudio -ClangbuilderRoot $ClangbuilderRoot -Arch $Arch -InstanceId $InstanceId -Sdklow:$Sdklow
InitializeExtranl -ClangbuilderRoot $ClangbuilderRoot -Arch $Arch


if ($Environment) {
    Update-Title -Title " [Environment]"
    Set-Location $ClangbuilderRoot
    return ;
}
else {
    Update-Title -Title " [Build: $Branch]"
}

# LLVM get from subversion
Function ParseLLVMDir {
    $obj = Get-Content -Path "$ClangbuilderRoot\config\revision.json" |ConvertFrom-Json
    switch ($Branch) {
        {$_ -eq "Mainline"} {
            $src = "$ClangbuilderRoot\out\mainline"
        } {$_ -eq "Stable"} {
            $currentstable = $obj.Stable
            $src = "$ClangbuilderRoot\out\$currentstable"
        } {$_ -eq "Release"} {
            $src = "$ClangbuilderRoot\out\rel\llvm"
        }
    }
    return $src
}

if ($Branch -eq "Release") {
    $Global:LLVMInitializeArgs = "$ClangbuilderRoot\bin\LLVMDownload.ps1 -LLDB:$LLDB"
    Write-Host "Build llvm release"
    $Global:LLVMSource = "$ClangbuilderRoot\out\rel\llvm"
}
else {
    $Global:LLVMInitializeArgs = "$ClangbuilderRoot\bin\LLVMRemoteFetch.ps1 -Branch $Branch  -LLDB:$LLDB"
    Write-Host "Build llvm branch $Branch"
    $Global:LLVMSource = &ParseLLVMDir
}


# Update LLVM sources
Invoke-Expression -Command $Global:LLVMInitializeArgs

$ArchTable = @{
    "x86"   = "";
    "x64"   = "Win64";
    "ARM"   = "ARM";
    "ARM64" = "ARM64"
}

$Global:ArchName = $ArchTable[$Arch];
$Global:ArchValue = $Arch;
# Builder CMake Arguments
$Global:Installation = $InstallationVersion.Substring(0, 2)
$Global:FinalWorkdir = ""
$Global:Flavor = $Flavor
$Global:CMakeArguments = "`"$Global:LLVMSource`""


if ($LLDB) {
    $PythonHome = Get-PythonHOME -Arch $Arch
    if ($null -eq $PythonHome) {
        Write-Error "Please Install Python 3.5+ ! "
        Exit 
    }
    Write-Host -ForegroundColor Yellow "Building LLVM with lldb,$Engine, $VisualStudioTarget"
    $Global:CMakeArguments += " -DLLDB_DISABLE_PYTHON=ON -DPYTHON_HOME=$PythonHome -DLLDB_RELOCATABLE_PYTHON=1"
}

$Global:CMakeArguments += " -DCMAKE_BUILD_TYPE=$Flavor  -DLLVM_ENABLE_ASSERTIONS=OFF"

if ($Branch -eq "Mainline") {
    $Global:CMakeArguments += " -DLLVM_APPEND_VC_REV=ON"
}
else {
    $Global:CMakeArguments += " -DLLVM_APPEND_VC_REV=OFF -DCLANG_REPOSITORY_STRING=`"clangbuilder.io`""
}


# -DLLVM_ENABLE_LIBCXX=ON -DLLVM_ENABLE_MODULES=ON -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON
$UpFlavor = $Flavor.ToUpper()
if ($Flavor -eq "Release" -or $Flavor -eq "MinSizeRel") {
    $MTStaticLINK = "MT"
}
else {
    $MTStaticLINK = "MTd"
}
if ($Static) {
    $Global:CMakeArguments += " -DLLVM_USE_CRT_$UpFlavor=$MTStaticLINK"
}

Function Set-Workdir {
    param(
        [String]$Path
    )
    if (Test-Path $Path) {
        Remove-Item -Force -Recurse "$Path"
    }
    New-Item -ItemType Directory $Path |Out-Null
    Set-Location $Path
}

Function Get-ClangArgument {
    $VisualCppVersionTable = @{
        "15" = "19.10";
        "14" = "19.00";
        "12" = "18.00";
        "11" = "17.00"
    };
    $ClangMarchArgument = @{
        "x64"   = "-m64";
        "x86"   = "-m32";
        "ARM"   = "--target=arm-pc-windows-msvc -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1";
        "ARM64" = "--target=arm64-pc-windows-msvc -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1"
    }
    if ($VisualCppVersionTable.ContainsKey($Global:Installation)) {
        $msvc = $VisualCppVersionTable[$Global:Installation]
    }
    else {
        $msvc = "19.10"
    }
    $Arguments = "-GNinja $Global:CMakeArguments"
    $ClangArgs = $ClangMarchArgument[$Global:ArchValue]
    $Arguments += " -DCMAKE_C_FLAGS=`"-fms-compatibility-version=$msvc $ClangArgs`""
    $Arguments += " -DCMAKE_CXX_FLAGS=`"-fms-compatibility-version=$msvc $ClangArgs`""
    if ($Global:Installation -eq "14" -or ($Global:Installation -eq "15")) {
        $Arguments += " -DLLVM_FORCE_BUILD_RUNTIME=ON -DLIBCXX_ENABLE_SHARED=YES"
        $Arguments += " -DLIBCXX_ENABLE_STATIC=YES -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=ON"
        #$Arguments += " -DLIBCXX_ENABLE_FILESYSTEM=ON"
    }
    return $Arguments
}

Function ClangNinjaGenerator {
    param(
        [String]$ClangExe,
        [String]$BuildDir
    )
    $env:CC = $ClangExe
    $env:CXX = $ClangExe
    Write-Host "Build llvm, Use: CC=$env:CC CXX=$env:CXX"
    Set-Workdir $BuildDir
    $Arguments = Get-ClangArgument
    $oe = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 ### Ninja need UTF8
    $exitcode = ProcessExec  -FilePath "cmake.exe" -Arguments $Arguments
    if ($exitcode -ne 0) {
        Write-Error "CMake exit: $exitcode"
        return 1
    }
    [Console]::OutputEncoding = $oe
    $PN = & Parallel
    $exitcode = ProcessExec -FilePath "ninja.exe" -Arguments "all -j $PN"
    return $exitcode
}


# Please see: http://libcxx.llvm.org/docs/BuildingLibcxx.html#experimental-support-for-windows

Function Invoke-MSBuild {
    $Global:FinalWorkdir = "$Global:ClangbuilderRoot\out\msbuild"
    Set-Workdir $Global:FinalWorkdir
    if ($Global:ArchName.Length -eq 0) {
        $Arguments = "-G`"Visual Studio $Global:Installation`" "
    }
    else {
        $Arguments = "-G`"Visual Studio $Global:Installation $Global:ArchName`" "
    }
    if ([System.Environment]::Is64BitOperatingSystem) {
        $Arguments += "-Thost=x64 ";
    }
    $Arguments += $Global:CMakeArguments
    $exitcode = ProcessExec  -FilePath "cmake" -Arguments $Arguments 
    if ($exitcode -ne 0) {
        Write-Error "CMake exit: $exitcode"
        return 1
    }
    $exitcode = ProcessExec -FilePath "cmake" -Arguments "--build . --config $Global:Flavor" 
    return $exitcode
}

Function Invoke-Ninja {
    $Global:FinalWorkdir = "$Global:ClangbuilderRoot\out\ninja"
    Set-Workdir $Global:FinalWorkdir
    $Arguments = "-GNinja $Global:CMakeArguments -DCMAKE_INSTALL_UCRT_LIBRARIES=ON"
    ### change oe
    $oe = [Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 ### Ninja need UTF8
    $exitcode = ProcessExec  -FilePath "cmake.exe" -Arguments $Arguments 
    if ($exitcode -ne 0) {
        Write-Error "CMake exit: $exitcode"
        return 1
    }
    $PN = & Parallel
    [Console]::OutputEncoding = $oe
    $exitcode = ProcessExec  -FilePath "ninja.exe" -Arguments "all -j $PN"
    return $exitcode
}

Function Get-PrebuiltLLVM {
    $PrebuiltJSON = "$Global:ClangbuilderRoot\config\prebuilt.json"
    if (!(Test-Path $PrebuiltJSON)) {
        return ""
    }
    $LLVMJSON = Get-Content -Path $PrebuiltJSON |ConvertFrom-Json
    if ($null -eq $LLVMJSON.LLVM) {
        return ""
    }
    $LLVMObj = $LLVMJSON.LLVM
    if ($null -eq $LLVMObj.Path) {
        return ""
    }
    return $LLVMObj.Path
}

Function Invoke-NinjaIterate {
    $PrebuiltLLVM = &Get-PrebuiltLLVM
    if ($PrebuiltLLVM -eq "") {
        return 1
    }
    if (!(Test-Path $PrebuiltLLVM)) {
        Write-Host "$PrebuiltLLVM not exists"
        return 1
    }
    $exitcode = ClangNinjaGenerator -ClangExe "$PrebuiltLLVM\bin\clang-cl.exe" -BuildDir "$Global:ClangbuilderRoot\out\prebuilt"
    return $exitcode
}

Function Invoke-NinjaBootstrap {
    $result = &Invoke-Ninja
    if ($result -ne 0) {
        Write-Error "Prebuild llvm due to error terminated !"
        return $result
    }
    $exitcode = ClangNinjaGenerator -ClangExe "$Global:FinalWorkdir\bin\clang-cl.exe" -BuildDir  "$Global:ClangbuilderRoot\out\bootstrap"
    return $exitcode
}

Write-Host "Use llvm build engine: $Engine"
$MyResult = -1


switch ($Engine) {
    "MSBuild" {
        $MyResult = Invoke-MSBuild
    }
    "Ninja" {
        $MyResult = Invoke-Ninja
    }
    "NinjaBootstrap" {
        $MyResult = Invoke-NinjaBootstrap
    }
    "NinjaIterate" {
        $MyResult = Invoke-NinjaIterate
    }
}


if ($MyResult -ne 0) {
    Write-Host -ForegroundColor Red "Engine: $Engine, Result: $MyResult"
    return ;
}
else {
    Write-Host "Build llvm completed, your can run cpack"
}

if ($Package) {
    if (Test-Path "$PWD/LLVM.sln") {
        CMakeInstallationFix -TargetDir "./projects/compiler-rt/lib" -Configuration $Flavor
    }
    &cpack -C "$Flavor"
}


Write-Host "compile llvm done, you can use it"

