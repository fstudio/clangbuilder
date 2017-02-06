<#############################################################################
#  ClangBuilderBootstrap.ps1
#  Note: Clang Auto Build TaskScheduler
#  Date:2016 02
#  Author:Force <forcemz@outlook.com>
##############################################################################>
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch="x64",

    [ValidateSet("Release", "Debug", "MinSizeRel", "RelWithDebug")]
    [String]$Flavor = "Release",

    [ValidateSet("110", "120", "140", "141", "150")]
    [String]$VisualStudio="120",
    [Switch]$Static,
    [Switch]$Released,
    [Switch]$Install,
    [Switch]$Clear
)

. "$PSScriptRoot/Initialize.ps1"

Update-Title -Title " [Bootstrap]"
$ClangbuilderRoot=Split-Path -Parent $PSScriptRoot

$Sdklow=$false
$VS="14.0"

switch($VisualStudio){
    {$_ -eq "110"}{
        $VS="11.0"
    }{$_ -eq "120"}{
        $VS="12.0"
    }{$_ -eq "140"}{
        $Sdklow=$true
        $VS="14.0"
    } {$_ -eq "141"}{
        $VS="14.0"
    } {$_ -eq "150"}{
        $Sdklow=$true
        $VS="15.0"
    } {$_ -eq "151"}{
        $VS="15.0"
    }
}


$ArchFlags="-m32"
if($Arch -eq "x64"){
    $ArchFlags="-m64"
}elseif($Arch -eq "x86"){
    $ArchFlags="-m32"
}elseif($Arch -eq "ARM"){
    $ArchFlags="--target=arm-pc-windows-msvc -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1"
    #FIXME
}elseif($Arch -eq "ARM64"){
    $ArchFlags="--target=arm64-pc-windows-msvc -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1"
    #FIXME
}

if($Clear){
    Reset-Environment
}

$ClangbuilderWorkdir="$ClangbuilderRoot\out\workdir"

Invoke-Expression -Command "$PSScriptRoot/PathLoader.ps1"
if($Sdklow){
    Invoke-Expression -Command "$PSScriptRoot/VisualStudioEnvinit.ps1 -Arch $Arch -VisualStudio $VS -Sdklow"
}else{
    Invoke-Expression -Command "$PSScriptRoot/VisualStudioEnvinit.ps1 -Arch $Arch -VisualStudio $VS"
}

if($Released){
    $SourcesDir="release"
    Write-Output "Build last released revision"
    Invoke-Expression -Command "$PSScriptRoot\LLVMInitialize.ps1"
}else{
    $SourcesDir="mainline"
    Write-Output "Build trunk branch"
    Invoke-Expression -Command "$PSScriptRoot\LLVMInitialize.ps1 -mainline"
}

if(!(Test-Path $ClangbuilderWorkdir)){
    mkdir -Force $ClangbuilderWorkdir
}else{
    Remove-Item -Force -Recurse "$ClangbuilderWorkdir\*"
}

Set-Location $ClangbuilderWorkdir

if($Static){
    $CRTLinkRelease="MT"
    $CRTLinkDebug="MTd"
}else{
    $CRTLinkRelease="MD"
    $CRTLinkDebug="MDd"
}

#stage0
if(!(Test-Path build_stage0)){
    mkdir -Force build_stage0
}
Set-Location build_stage0

&cmake "..\..\$SourcesDir" -GNinja -DCMAKE_CONFIGURATION_TYPES="$Flavor" -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_BUILD_TYPE="$Flavor" -DLLVM_USE_CRT_RELEASE="$CRTLinkRelease" -DLLVM_USE_CRT_MINSIZEREL="$CRTLinkRelease" -DLLVM_APPEND_VC_REV=ON 
if($lastexitcode -ne 0){
    exit 1
}
&ninja all 
if($lastexitcode -ne 0){
    exit 1
}

Set-Location $ClangbuilderWorkdir

if(!(Test-Path build)){
    mkdir build
}
Write-Output "Use clang-cl bootstrap llvm now: "
Set-Location build
$env:CC="..\build_stage0\bin\clang-cl"
$env:CXX="..\build_stage0\bin\clang-cl"
$env:cflags="-fmsc-version=$MSVCFull $ArchFlags $env:cflags"
$env:cxxflags="-fmsc-version=$MSVCFull $ArchFlags $env:cxxflags"

# -fmsc-version=1900
&cmake "..\..\$SourcesDir" -GNinja -DCMAKE_CONFIGURATION_TYPES="$Flavor" -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_BUILD_TYPE="$Flavor" -DLLVM_USE_CRT_RELEASE="$CRTLinkRelease" -DLLVM_USE_CRT_MINSIZEREL="$CRTLinkRelease" -DLLVM_APPEND_VC_REV=ON 
if($lastexitcode -ne 0){
    exit 1
}
&ninja all 
if($lastexitcode -ne 0){
    exit 1
}

Write-Output "ClangBuilderBootstrap build success !"

if($Install){
    &ninja package 
    if($lastexitcode -ne 0){
        Write-Output "Make installation package failed "
    }else{
        Write-Output "Make installation package success "
    }
}

Set-Location ..
