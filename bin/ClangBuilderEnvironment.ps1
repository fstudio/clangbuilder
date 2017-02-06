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
    [Switch]$Clear
)

. "$PSScriptRoot/Initialize.ps1"

Update-Title -Title " [Env]"

$ClangbuilderRoot=Split-Path -Parent $PSScriptRoot


if($Clear){
    Reset-Environment
}

Invoke-Expression -Command "$PSScriptRoot/PathLoader.ps1"
Invoke-Expression -Command "$PSScriptRoot/Model/VisualStudioSub$VisualStudio.ps1 -Arch $Arch"



Write-Output "Clangbuilder Environment configure done
Visual Studio $VisualStudioVersion Arch $Arch 
V110 - Visual Studio 2012
V120 - Visual Studio 2013
V140 - Visual Studio 2015 Windows 8.1 SDK
V141 - Visual Studio 2015 Windows 10 SDK
V150 - Visual Studio 2017
"
