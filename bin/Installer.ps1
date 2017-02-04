<#############################################################################
#  Install.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.03
#  Author:Force <forcemz@outlook.com>
##############################################################################>
param(
    [Switch]$Reset
)
IF($PSVersionTable.PSVersion.Major -lt 3)
{
    Write-Error "Clangbuilder Require PowerShell 3 or Later,`nYour PowerShell version Is :${Host}"
    [System.Console]::ReadKey()
    return
}

$ClangbuilderRoot=Split-Path -Parent $PSScriptRoot


. "$ClangbuilderRoot/tools/RestoreUtilitytools.ps1"

if(!(Test-Path "$ClangbuilderRoot/pkgs")){
    mkdir -Path "$ClangbuilderRoot/pkgs"
}

if($Reset){
    Remove-Item -Recurse -Force "$ClangbuilderRoot/pkgs/*"
}
Invoke-Expression -Command "$PSScriptRoot/PkgInitialize.ps1"
