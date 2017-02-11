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

    [ValidateSet("110", "120", "140", "141", "150","151")]
    [String]$VisualStudio="140",
    [Switch]$Clear
)

. "$PSScriptRoot/Initialize.ps1"

Update-Title -Title " [Environment]"

$Sdklow=$false
$VS=$VisualStudio.Substring(0,2)+".0"

if($VisualStudio -eq "140" -or ($VisualStudio -eq "150")){
    $Sdklow=$true
}

$ClangbuilderRoot=Split-Path -Parent $PSScriptRoot


if($Clear){
    Reset-Environment
}

Invoke-Expression -Command "$PSScriptRoot/PathLoader.ps1"
if($Sdklow){
    Invoke-Expression -Command "$PSScriptRoot/VisualStudioEnvinit.ps1 -Arch $Arch -VisualStudio $VS -Sdklow"
}else{
    Invoke-Expression -Command "$PSScriptRoot/VisualStudioEnvinit.ps1 -Arch $Arch -VisualStudio $VS"
}



Write-Output "Clangbuilder Environment configure done
Visual Studio $VS - $Arch 
"
