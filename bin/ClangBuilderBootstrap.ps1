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

if($PSVersionTable.PSVersion.Major -lt 3)
{
    $PSVersionString=$PSVersionTable.PSVersion.Major
    Write-Error "Clangbuilder must run under PowerShell 3.0 or later host environment !"
    Write-Error "Your PowerShell Version:$PSVersionString"
    if($Host.Name -eq "ConsoleHost"){
        [System.Console]::ReadKey()
    }
    Exit
}

$Host.UI.RawUI.WindowTitle="Clangbuilder [Bootstrap Channel]"
Write-Output "ClangBuilder Utility tools [Bootstrap Channel]"
Write-Output "Copyright $([Char]0xA9) 2016. FroceStudio. All Rights Reserved."

$ClangbuilderRoot=Split-Path -Parent $PSScriptRoot
. "$PSScriptRoot\ClangBuilderUtility.ps1"

$VSTools="12"
$MSVCFull="1800"
if($VisualStudio -eq "110"){
    $VSTools="11"
	$MSVCFull="1700"
}elseif($VisualStudio -eq "120"){
    $VSTools="12"
    $MSVCFull="1800"
}elseif($VisualStudio -eq "140"){
    $VSTools="14"
    $MSVCFull="1900"
}elseif($VisualStudio -eq "141"){
    $VSTools="14"
    $MSVCFull="1900"
}elseif($VisualStudio -eq "150"){
    $VSTools="15"
    $MSVCFull="2000"
}ELSE{
    Write-Error "Unknown VisualStudio Version: $VisualStudio"
}

$ArchFlags="-m32"
if($Arch -eq "x64"){
    $ArchFlags="-m64"
}elseif($Arch -eq "x86"){
    $ArchFlags="-m32"
}elseif($Arch -eq "ARM"){
    #$ArchFlags="--target=arm-v7a-pc-win32"
    #FIXME
}else if($Arch -eq "ARM64"){
    #FIXME
}

if($Clear){
    Reset-Environment
}

$ClangbuilderWorkdir="$ClangbuilderRoot\out\workdir"

Invoke-Expression -Command "$PSScriptRoot\Model\VisualStudioSub$VisualStudio.ps1 $Arch"
Invoke-Expression -Command "$PSScriptRoot\DiscoverToolChain.ps1"

if($Released){
    $SourcesDir="release"
    Write-Output "Build last released revision"
    Invoke-Expression -Command "$PSScriptRoot\RestoreClangReleased.ps1"
}else{
    $SourcesDir="mainline"
    Write-Output "Build trunk branch"
    Invoke-Expression -Command "$PSScriptRoot\RestoreClangMainline.ps1"
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
