<#############################################################################
#  ClangBuilderEnvironmnet.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>
##############################################################################>
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch="x64",

    [ValidateSet("Release", "Debug", "MinSizeRel", "RelWithDebug")]
    [String]$Flavor = "Release",

    [ValidateSet("110", "120", "140", "141", "150")]
    [String]$VisualStudio="120",
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

$Host.UI.RawUI.WindowTitle="Clangbuilder PowerShell Utility"

Write-Output "Clang Auto Builder [PowerShell] Utility tools"
Write-Output "Copyright $([Char]0xA9) 2016. FroceStudio. All Rights Reserved."

$SelfFolder=$PSScriptRoot;

. "$SelfFolder/ClangBuilderUtility.ps1"


if($CleanEnv){
    Clear-Environment
}


Invoke-Expression -Command "$SelfFolder/Model/VisualStudioSub$VisualStudio.ps1 -Arch $Arch"
Invoke-Expression -Command "$SelfFolder/DiscoverToolChain.ps1"

Write-Output "Clangbuilder Environment Set done
Visual Studio $VisualStudioVersion Arch $Arch
V110 - VisualStudio 2012
V120 - VisualStudio 2013
V140 - VisualStudio 2015 Windows 8.1 SDK
V141 - VisualStudio 2015 Windows 10 SDK
"
