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
    Write-Error "Visual Studio Enviroment vNext Must Run on Windows PowerShell 3 or Later,`nYour PowerShell version Is :${Host}"
    [System.Console]::ReadKey()
    return
}

$SelfParent=Split-Path -Parent $PSScriptRoot
$ClangbuilderRoot=Split-Path -Parent $SelfParent


. "$ClangbuilderRoot/tools/RestoreUtilitytools.ps1"

if($Reset){
    Remove-Item -Recurse -Force "$ClangbuilderRoot/packages/*" -Exclude "*.ps1"
}
Invoke-Expression -Command "$ClangbuilderRoot/packages/PkgInstaller.ps1"
