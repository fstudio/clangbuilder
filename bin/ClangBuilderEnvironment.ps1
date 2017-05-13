<#############################################################################
#  ClangBuilderEnvironmnet.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>
##############################################################################>
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch = "x64",

    [ValidateSet("Release", "Debug", "MinSizeRel", "RelWithDebug")]
    [String]$Flavor = "Release",

    [ValidateSet("110", "120", "140", "141", "150", "151")]
    [String]$VisualStudio = "140",
    [Switch]$Clear
)

. "$PSScriptRoot/Initialize.ps1"



$Sdklow = $false
$VS = $VisualStudio.Substring(0, 2) + ".0"

if ($VisualStudio -eq "140" -or ($VisualStudio -eq "150")) {
    $Sdklow = $true
}

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
$ArchText=$ArchList[$Arch]
Update-Title -Title " [$VisualStudioProduction] - $ArchText"

$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot


if ($Clear) {
    Reset-Environment
}

Invoke-Expression -Command "$PSScriptRoot/PathLoader.ps1"
if ($Sdklow) {
    $VisualStudioArgs += " -Sdklow"
}
$VisualStudioArgs = "$PSScriptRoot/VisualStudioEnvinit.ps1 -Arch $Arch -VisualStudio $VS"
Invoke-Expression -Command $VisualStudioArgs
Invoke-Expression -Command "$PSScriptRoot/Extranllibs.ps1 -Arch $Arch"
Write-Output "Clangbuilder Environment configure done
Visual Studio $VS - $Arch 
"
