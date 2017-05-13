<#############################################################################
#  ClangBuilderBootstrap.ps1
#  Note: Clang Auto Build TaskScheduler
#  Date:2016 02
#  Author:Force <forcemz@outlook.com>
##############################################################################>
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch = "x64",

    [ValidateSet("Release", "Debug", "MinSizeRel", "RelWithDebug")]
    [String]$Flavor = "Release",

    [ValidateSet("110", "120", "140", "141", "150", "151")]
    [String]$VisualStudio = "120",
    [Switch]$Static,
    [Switch]$Released,
    [Switch]$Install,
    [Switch]$Clear
)

. "$PSScriptRoot/Initialize.ps1"

Update-Title -Title " [Bootstrap]"
$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot

$Sdklow = $false
$VSTools = $VisualStudio.Substring(0, 2)
$VS = "$VSTools.0"

if ($VisualStudio -eq "140" -or ($VisualStudio -eq "150")) {
    $Sdklow = $true
}


$ArchFlags = "-m32"
if ($Arch -eq "x64") {
    $ArchFlags = "-m64"
}
elseif ($Arch -eq "x86") {
    $ArchFlags = "-m32"
}
elseif ($Arch -eq "ARM") {
    $ArchFlags = "--target=arm-pc-windows-msvc -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1"
    #FIXME
}
elseif ($Arch -eq "ARM64") {
    $ArchFlags = "--target=arm64-pc-windows-msvc -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1"
    #FIXME
}

if ($Clear) {
    Reset-Environment
}

$ClangbuilderWorkdir = "$ClangbuilderRoot\out\workdir"

$VisualStudioArgs = "$PSScriptRoot/VisualStudioEnvinit.ps1 -Arch $Arch -VisualStudio $VS"
Invoke-Expression -Command "$PSScriptRoot/PathLoader.ps1"
if ($Sdklow) {
    $VisualStudioArgs += " -Sdklow"
}
Invoke-Expression -Command $VisualStudioArgs
Invoke-Expression -Command "$PSScriptRoot/Extranllibs.ps1 -Arch $Arch"


$LLVMInitializeArgs = "$ClangbuilderRoot\bin\LLVMInitialize.ps1"
if ($Released) {
    Write-Output "LLVM Release Tag"
    $LLVMSource = "$ClangbuilderRoot\out\release"
}
else {
    Write-Output "LLVM Mainline branch"
    $LLVMSource = "$ClangbuilderRoot\out\mainline"
    $LLVMInitializeArgs += " -Mainline"
}

if ($LLDB) {
    $LLVMInitializeArgs += " -LLDB"
}

# Update LLVM sources
Invoke-Expression -Command $LLVMInitializeArgs

if (!(Test-Path $ClangbuilderWorkdir)) {
    mkdir -Force $ClangbuilderWorkdir
}
else {
    Remove-Item -Force -Recurse "$ClangbuilderWorkdir\*"
}

Set-Location $ClangbuilderWorkdir

if ($Static) {
    $CRTLinkRelease = "MT"
    $CRTLinkDebug = "MTd"
}
else {
    $CRTLinkRelease = "MD"
    $CRTLinkDebug = "MDd"
}

#stage0
if (!(Test-Path build_stage0)) {
    mkdir -Force build_stage0
}
Set-Location build_stage0

&cmake "$LLVMSource" -GNinja -DCMAKE_CONFIGURATION_TYPES="$Flavor" -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_BUILD_TYPE="$Flavor" -DLLVM_USE_CRT_RELEASE="$CRTLinkRelease" -DLLVM_USE_CRT_MINSIZEREL="$CRTLinkRelease" -DLLVM_APPEND_VC_REV=ON 
if ($lastexitcode -ne 0) {
    exit 1
}
&ninja all 
if ($lastexitcode -ne 0) {
    exit 1
}

Set-Location $ClangbuilderWorkdir

if (!(Test-Path build)) {
    mkdir build
}
Write-Output "Use clang-cl bootstrap llvm now: "
Set-Location build
$env:CC = "..\build_stage0\bin\clang-cl"
$env:CXX = "..\build_stage0\bin\clang-cl"
$env:cflags = "-fmsc-version=$MSVCFull $ArchFlags $env:cflags"
$env:cxxflags = "-fmsc-version=$MSVCFull $ArchFlags $env:cxxflags"

# -fmsc-version=1900
&cmake "$LLVMSource" -GNinja -DCMAKE_CONFIGURATION_TYPES="$Flavor" -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_BUILD_TYPE="$Flavor" -DLLVM_USE_CRT_RELEASE="$CRTLinkRelease" -DLLVM_USE_CRT_MINSIZEREL="$CRTLinkRelease" -DLLVM_APPEND_VC_REV=ON 
if ($lastexitcode -ne 0) {
    exit 1
}
&ninja all 
if ($lastexitcode -ne 0) {
    exit 1
}

Write-Output "ClangBuilderBootstrap build success !"

if ($Install) {
    &ninja package 
    if ($lastexitcode -ne 0) {
        Write-Output "Make installation package failed "
    }
    else {
        Write-Output "Make installation package success "
    }
}

Set-Location ..
