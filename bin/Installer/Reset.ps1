<####################################################################################################################
# ClangSetup Environment Reset Feature
# 
#
####################################################################################################################>
IF($PSVersionTable.PSVersion.Major -lt 3)
{
Write-Host -ForegroundColor Red "Visual Studio Enviroment vNext Must Run on Windows PowerShell 3 or Later,`nYour PowerShell version Is : 
${Host}"
[System.Console]::ReadKey()
return 
}

$REACDIR=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
$CSERoot=Split-Path -Parent $REACDIR
$CSERoot=Split-Path -Parent $CSERoot
Invoke-Expression "$REACDIR\Update.ps1"

Get-GithubUpdatePackage $CSERoot

Remove-Item -Force -Recurse "${CSERoot}\Packages\*" -Exclude PackageList.txt

Invoke-Expression -Command "PowerShell -NoLogo -NoExit -File ${CSERoot}\InstallClangSetupvNext.ps1"
