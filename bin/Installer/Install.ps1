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

$SelfFolder=$PSScriptRoot;
$SelfParent=Split-Path -Parent $SelfFolder
$ClangbuilderRoot=Split-Path -Parent $SelfParent


. "$ClangbuilderRoot/tools/RestoreUtilitytools.ps1"

if($Reset){
    Remove-Item -Recurse -Force "$ClangbuilderRoot/Packages/*" -Exclude "*.ps1"
}
Invoke-Expression -Command "$ClangbuilderRoot/Packages/RestorePackages.ps1"
