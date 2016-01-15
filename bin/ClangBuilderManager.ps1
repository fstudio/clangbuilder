<#############################################################################
#  ClangBuilderManager.ps1
#  Note: Clang Auto Build TaskScheduler
#  Date:2016 01
#  Author:Force <forcemz@outlook.com>
##############################################################################>
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch="x64",

    [ValidateSet("Release", "Debug", "MinSizeRel", "RelWithDebug")]
    [String]$Flavor = "Release",

    [ValidateSet("110", "120", "140", "141", "150")]
    [String]$VisualStudio="120",
    [Switch]$LLDB,
    [Switch]$Static,
    [Switch]$NMake,
    [Switch]$Released,
    [Switch]$Install,
    [Switch]$CleanEnv
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
$WindowTitlePrefix="Clangbuilder PowerShell Utility"
Write-Output "Clang Auto Builder [PowerShell] Utility tools"
Write-Output "Copyright $([Char]0xA9) 2016. FroceStudio. All Rights Reserved."

$SelfFolder=$PSScriptRoot;
$ClangbuilderRoot=Split-Path -Parent $SelfFolder
. "$SelfFolder/ClangBuilderUtility.ps1"

if($VisualStudio -eq "110"){
    $VSTools="11"
}elseif($VisualStudio -eq "120"){
    $VSTools="12"
}elseif($VisualStudio -eq "140"){
    $VSTools="14"
}elseif($VisualStudio -eq "141"){
    $VSTools="14"
}elseif($VisualStudio -eq "150"){
    $VSTools="15"
}ELSE{
    Write-Error "Unknown VisualStudio Version: $VisualStudio"
}

if($CleanEnv){
    Clear-Environment
}

Invoke-Expression -Command "$SelfFolder/Model/VisualStudioSub$VisualStudio.ps1 $Arch"
Invoke-Expression -Command "$SelfFolder/DiscoverToolChain.ps1"

if($LLDB){
    if(!(Test-Path "$SelfFolder/Required/Python/python.exe")){
        $LLDB=$False
    }
}

if($Install){
    $SourcesDir="release"
    if($LLDB){
        Invoke-Expression -Command "$SelfFolder/RestoreClangReleased.ps1 -EnableLLDB"
    }else{
        Invoke-Expression -Command "$SelfFolder/RestoreClangReleased.ps1"
    }
}else{
    $SourcesDir="mainline"
    if($LLDB){
        Invoke-Expression -Command "$SelfFolder/RestoreClangMainline.ps1 -EnableLLDB"
    }else{
        Invoke-Expression -Command "$SelfFolder/RestoreClangMainline.ps1"
    }
}

if(!(Test-Path "$ClangbuilderRoot/out/workdir")){
    mkdir -Force "$ClangbuilderRoot/out/workdir"
}else{
    Remove-Item -Force -Recurse "$ClangbuilderRoot/out/workdir/*"
}

Set-Location "$ClangbuilderRoot/out/workdir"

if($Static){
    $CRTLinkRelease="MT"
    $CRTLinkDebug="MTd"
}else{
    $CRTLinkRelease="MD"
    $CRTLinkDebug="MDd"
}


Function Start-NMakeBuilder{
    &cmake "..\$SourcesDir" -G`"NMake Makefiles`" -DCMAKE_CONFIGURATION_TYPES=$Flavor -DCMAKE_BUILD_TYPE=$Flavor -DLLVM_USE_CRT_DEBUG=$CRTLinkDebug -DLLVM_USE_CRT_RELEASE=$CRTLinkRelease -DLLVM_USE_CRT_MINSIZEREL=$CRTLinkRelease -DLLVM_USE_CRT_RELWITHDBGINFO=$CRTLinkRelease    -DLLVM_APPEND_VC_REV:BOOL=ON
    if(Test-Path "Makefile"){
    &nmake
    }
}


Function Start-MSBuild{
    if($Arch -eq "x64"){
        &cmake "..\$SourcesDir" -G`"Visual Studio $VSTools Win64`" -DCMAKE_CONFIGURATION_TYPES=$Flavor -DCMAKE_BUILD_TYPE=$Flavor -DLLVM_USE_CRT_DEBUG=$CRTLinkDebug -DLLVM_USE_CRT_RELEASE=$CRTLinkRelease -DLLVM_USE_CRT_MINSIZEREL=$CRTLinkRelease -DLLVM_USE_CRT_RELWITHDBGINFO=$CRTLinkRelease    -DLLVM_APPEND_VC_REV:BOOL=ON
        if(Test-Path "LLVM.sln"){
            &msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration=$Flavor /p:Platform=x64 /t:ALL_BUILD
        }

    }elseif($Arch -eq "ARM"){
        &cmake "..\$SourcesDir" -G`"Visual Studio $VSTools ARM`" -DCMAKE_CONFIGURATION_TYPES=$Flavor -DCMAKE_BUILD_TYPE=$Co$Flavornfiguration -DLLVM_USE_CRT_DEBUG=$CRTLinkDebug -DLLVM_USE_CRT_RELEASE=$CRTLinkRelease -DLLVM_USE_CRT_MINSIZEREL=$CRTLinkRelease -DLLVM_USE_CRT_RELWITHDBGINFO=$CRTLinkRelease    -DLLVM_APPEND_VC_REV:BOOL=ON
        if(Test-Path "LLVM.sln"){
            &msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration=$Flavor /p:Platform=ARM /t:ALL_BUILD
        }

    }elseif($Arch -eq "ARM64" -and $VisualStudio -ge 141){
        &cmake "..\$SourcesDir" -G`"Visual Studio $VSTools ARM64`" -DCMAKE_CONFIGURATION_TYPES=$Flavor -DCMAKE_BUILD_TYPE=$Configuration -DLLVM_USE_CRT_DEBUG=$CRTLinkDebug -DLLVM_USE_CRT_RELEASE=$CRTLinkRelease -DLLVM_USE_CRT_MINSIZEREL=$CRTLinkRelease -DLLVM_USE_CRT_RELWITHDBGINFO=$CRTLinkRelease    -DLLVM_APPEND_VC_REV:BOOL=ON
        if(Test-Path "LLVM.sln"){
            &msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration=$Flavor /p:Platform=ARM64 /t:ALL_BUILD
        }
    }else{
        &cmake "..\$SourcesDir" -G`"Visual Studio $VSTools`" -DCMAKE_CONFIGURATION_TYPES=$Flavor -DCMAKE_BUILD_TYPE=$Configuration -DLLVM_USE_CRT_DEBUG=$CRTLinkDebug -DLLVM_USE_CRT_RELEASE=$CRTLinkRelease -DLLVM_USE_CRT_MINSIZEREL=$CRTLinkRelease -DLLVM_USE_CRT_RELWITHDBGINFO=$CRTLinkRelease    -DLLVM_APPEND_VC_REV:BOOL=ON
        if(Test-Path "LLVM.sln"){
            &msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration=$Flavor /p:Platform=win32 /t:ALL_BUILD
        }
    }
}


if($NMake){
    Start-NMakeBuilder
}else{
    Start-MSBuild
}


if($lastexitcode -eq 0 -and $Install){
    if(Test-Path "$PWD/LLVM.sln"){
        &cpack -C $Flavor
    }
}
