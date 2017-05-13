<#############################################################################
#  ClangBuilderManager.ps1
#  Note: Clang Auto Build TaskScheduler
#  Date:2016 01
#  Author:Force <forcemz@outlook.com>
##############################################################################>
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch = "x64",

    [ValidateSet("Release", "Debug", "MinSizeRel", "RelWithDebug")]
    [String]$Flavor = "Release",

    [ValidateSet("110", "120", "140", "141", "150", "151")]
    [String]$VisualStudio = "120",
    [Switch]$LLDB,
    [Switch]$Static,
    [Switch]$NMake,
    [Switch]$Released,
    [Switch]$Install,
    [Switch]$Clear
)

. "$PSScriptRoot/Initialize.ps1"

$VisualStudioList = @{
    "151" = "Visual Studio 2017";
    "150" = "Visual Studio 2017 for Windows 8.1";
    "141" = "Visual Studio 2015";
    "140" = "Visual Studio 2015 for Windows 8.1";
    "120" = "Visual Studio 2013";
    "110" = "Visual Studio 2012"
}
$ArchList = @{
    "x86"   = "";
    "x64"   = "Win64";
    "ARM"   = "ARM";
    "ARM64" = "ARM64"
}
$VisualStudioProduction = $VisualStudioList[$VisualStudio]
$ArchText = $ArchList[$Arch]
Update-Title -Title " [$VisualStudioProduction] - $ArchText"

$Global:ClangbuilderRoot = Split-Path -Parent $PSScriptRoot
$Global:LLDB = $LLDB
$Global:Flavor = $Flavor
$Global:Released = $Released
$Global:Install = $Install

$Sdklow = $false
$VSTools = $VisualStudio.Substring(0, 2)
$VS = "$VSTools.0"

if ($VisualStudio -eq "140" -or ($VisualStudio -eq "150")) {
    $Sdklow = $true
}


if ($Clear) {
    Reset-Environment
}

$VisualStudioArgs = "$PSScriptRoot/VisualStudioEnvinit.ps1 -Arch $Arch -VisualStudio $VS"
Invoke-Expression -Command "$PSScriptRoot/PathLoader.ps1"
if ($Sdklow) {
    $VisualStudioArgs += " -Sdklow"
}
Invoke-Expression -Command $VisualStudioArgs
Invoke-Expression -Command "$PSScriptRoot/Extranllibs.ps1 -Arch $Arch"

# Update LLVMInitialize Script command
$Global:LLVMInitializeArgs = "$Global:ClangbuilderRoot\bin\LLVMInitialize.ps1"
if ($Released) {
    Write-Output "LLVM Release Tag"
    $Global:LLVMSource = "$Global:ClangbuilderRoot\out\release"
}
else {
    Write-Output "LLVM Mainline branch"
    $Global:LLVMSource = "$Global:ClangbuilderRoot\out\mainline"
    $Global:LLVMInitializeArgs += " -Mainline"
}

if ($Global:LLDB) {
    $Global:LLVMInitializeArgs += " -LLDB"
}

# Update LLVM sources
Invoke-Expression -Command $Global:LLVMInitializeArgs

### Cleanup workdir
if (!(Test-Path "$ClangbuilderRoot/out/workdir")) {
    mkdir -Force "$ClangbuilderRoot/out/workdir"
}
else {
    Remove-Item -Force -Recurse "$ClangbuilderRoot/out/workdir/*"
}

Set-Location "$ClangbuilderRoot/out/workdir"

# Builder CMake Arguments
$Global:CMakeArguments = "`"$Global:LLVMSource`""

if ($NMake) {
    $Global:CMakeArguments += " -G`"NMake Makefiles`""
    Update-Title " (NMake)"
}
else {
    $Global:CMakeArguments += " -G`"Visual Studio $VSTools $ArchText`""
}

$Global:CMakeArguments += " -DCMAKE_CONFIGURATION_TYPES=$Flavor -DCMAKE_BUILD_TYPE=$Flavor -DLLVM_APPEND_VC_REV=ON"

if ($Static) {
    $Global:CMakeArguments += " -DLLVM_USE_CRT_RELEASE=MT -DLLVM_USE_CRT_MINSIZEREL=MT "
}


if ($LLDB) {
    . "$PSScriptRoot\LLDBInitialize.ps1"
    $PythonHome = Get-Pyhome -Arch $Arch
    if ($null -eq $PythonHome) {
        Write-Error "Please Install Python 3.5+ ! "
        Exit 
    }
    Write-Host -ForegroundColor Yellow "Building LLVM with lldb,msbuild, $VisualStudioTarget"
    $Global:CMakeArguments += " -DPYTHON_HOME=`"$PythonHome`" -DLLDB_RELOCATABLE_PYTHON=1"
}
&cmake $Global:CMakeArguments.Split()
if ($lastexitcode -ne 0) {
    Write-Error "CMake exit: $lastexitcode"
    return ;
}
&cmake --build . --config "$Flavor"

Function Global:FixInstall {
    param(
        [String]$TargetDir,
        [String]$Configuration
    )
    $filelist = Get-ChildItem "$TargetDir"  -Recurse *.cmake | Foreach-Object {$_.FullName}
    foreach ($file in $filelist) {
        $content = Get-Content $file
        Clear-Content $file
        foreach ($line in $content) {
            $lr = $line.Replace("`$(Configuration)", "$Configuration")
            Add-Content $file -Value $lr
        }
    }
}

if ($lastexitcode -eq 0 -and $Install) {
    if (Test-Path "$PWD/LLVM.sln") {
        #$(Configuration)
        FixInstall -TargetDir "./projects/compiler-rt/lib" -Configuration $Flavor
        &cpack -C "$Flavor"
    }
}


Function Global:Update-Build {
    Invoke-Expression -Command $Global:LLVMInitializeArgs
    Set-Location "$Global:ClangbuilderRoot/out/workdir"
    &cmake --build . --config "$Global:Flavor"
    if ($Global:Install) {
        FixInstall -TargetDir "./projects/compiler-rt/lib" -Configuration $Global:Flavor
        &cpack -C "$Flavor"
    }
}
