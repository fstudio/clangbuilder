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

Update-Title -Title " [Building]"

$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot


$Sdklow = $false
$VSTools = $VisualStudio.Substring(0, 2)
$VS = "$VSTools.0"

if ($VisualStudio -eq "140" -or ($VisualStudio -eq "150")) {
    $Sdklow = $true
}


if ($Clear) {
    Reset-Environment
}

Invoke-Expression -Command "$PSScriptRoot/PathLoader.ps1"
if ($Sdklow) {
    Invoke-Expression -Command "$PSScriptRoot/VisualStudioEnvinit.ps1 -Arch $Arch -VisualStudio $VS -Sdklow"
}
else {
    Invoke-Expression -Command "$PSScriptRoot/VisualStudioEnvinit.ps1 -Arch $Arch -VisualStudio $VS"
}

Invoke-Expression -Command "$PSScriptRoot/Extranllibs.ps1 -Arch $Arch"

# Move value to global
$Global:LLDB = $LLDB
$Global:Flavor = $Flavor
$Global:Released = $Released
$Global:Install = $Install
$Global:ClangbuilderRoot = $ClangbuilderRoot


Function Global:Update-LLVM {
    if ($Global:Released) {
        $Global:LLVMSource = "$Global:ClangbuilderRoot\out\release"
        Write-Output "Build last released revision"
        if ($Global:LLDB) {
            Invoke-Expression -Command "$Global:ClangbuilderRoot\bin\LLVMInitialize.ps1 -LLDB" 
        }
        else {
            Invoke-Expression -Command "$Global:ClangbuilderRoot\bin\LLVMInitialize.ps1" 
        }
    }
    else {
        $Global:LLVMSource = "$Global:ClangbuilderRoot\out\release"
        Write-Output "Build trunk branch"
        if ($Global:LLDB) {
            Invoke-Expression -Command "$Global:ClangbuilderRoot\bin\LLVMInitialize.ps1 -LLDB -Mainline" 
        }
        else {
            Invoke-Expression -Command "$Global:ClangbuilderRoot\bin\LLVMInitialize.ps1 -Mainline" 
        }
    }
}

Update-LLVM

if (!(Test-Path "$ClangbuilderRoot/out/workdir")) {
    mkdir -Force "$ClangbuilderRoot/out/workdir"
}
else {
    Remove-Item -Force -Recurse "$ClangbuilderRoot/out/workdir/*"
}

Set-Location "$ClangbuilderRoot/out/workdir"

if ($Static) {
    $CRTLinkRelease = "MT"
    $CRTLinkDebug = "MTd"
}
else {
    $CRTLinkRelease = "MD"
    $CRTLinkDebug = "MDd"
}


$VisualStudioTarget = "Visual Studio $VSTools"

if ($Arch -eq "x64") {
    $VisualStudioTarget += " Win64"
}
elseif ($Arch -eq "ARM") {
    $VisualStudioTarget += " ARM"
}
elseif ($Arch -eq "ARM64") {
    $VisualStudioTarget += " ARM64"
}

if ($LLDB) {
    . "$PSScriptRoot\LLDBInitialize.ps1"
    $PythonHome = Get-Pyhome -Arch $Arch
    if ($null -eq $PythonHome) {
        Write-Error "Not Found python 3.5 or later install on your system ! "
        Exit 
    }
    Write-Host -ForegroundColor Yellow "Building LLVM with lldb,msbuild, $VisualStudioTarget"
    &cmake "$Global:LLVMSource" -G $VisualStudioTarget -DPYTHON_HOME="$PythonHome" -DLLDB_RELOCATABLE_PYTHON=1  -DCMAKE_CONFIGURATION_TYPES="$Flavor"  -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_BUILD_TYPE="$Flavor" -DLLVM_USE_CRT_RELEASE="$CRTLinkRelease" -DLLVM_USE_CRT_MINSIZEREL="$CRTLinkRelease" -DLLVM_APPEND_VC_REV=ON 
    if (Test-Path "LLVM.sln") {
        #&msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration="$Flavor" /p:Platform=x64 /t:ALL_BUILD
        &cmake --build . --config "$Flavor"
    }
}
else {
    if ($NMake) {
        $NumberOfLogicalProcessors = (Get-WmiObject Win32_Processor).NumberOfLogicalProcessors
        Write-Output "Processor count: $NumberOfLogicalProcessors"
        Write-Host -ForegroundColor Yellow "Building LLVM without lldb, NMake, $VisualStudioTarget"
        cmake "$Global:LLVMSource" -G"NMake Makefiles" -DCMAKE_CONFIGURATION_TYPES="$Flavor" -DCMAKE_BUILD_TYPE="$Flavor"  -DLLVM_ENABLE_ASSERTIONS=ON -DLLVM_USE_CRT_RELEASE="$CRTLinkRelease" -DLLVM_USE_CRT_MINSIZEREL="$CRTLinkRelease" -DLLVM_APPEND_VC_REV=ON
        if (Test-Path "Makefile") {
            &cmake --build . --config "$Flavor"
        }
    }
    else {
        Write-Host -ForegroundColor Yellow "Building LLVM without lldb, msbuild, $VisualStudioTarget"
        &cmake "$Global:LLVMSource" -G $VisualStudioTarget -DCMAKE_CONFIGURATION_TYPES="$Flavor"  -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_BUILD_TYPE="$Flavor" -DLLVM_USE_CRT_RELEASE="$CRTLinkRelease" -DLLVM_USE_CRT_MINSIZEREL="$CRTLinkRelease" -DLLVM_APPEND_VC_REV=ON
        if (Test-Path "LLVM.sln") {
            #&msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration="$Flavor" /p:Platform=x64 /t:ALL_BUILD
            &cmake --build . --config "$Flavor"
        }
    }
}


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
    Update-LLVM
    Set-Location "$Global:ClangbuilderRoot/out/workdir"
    &cmake --build . --config "$Global:Flavor"
    if ($Global:Install) {
        FixInstall -TargetDir "./projects/compiler-rt/lib" -Configuration $Global:Flavor
        &cpack -C "$Flavor"
    }
}
