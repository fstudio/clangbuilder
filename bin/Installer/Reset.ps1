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
$SelfFolder=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
$SelfParent=Split-Path -Parent $SelfFolder
$ClangbuilderRoot=Split-Path -Parent $SelfParent

Invoke-Expression "$SelfFolder\Update.ps1"

Get-GithubUpdatePackage -Root $ClangbuilderRoot

#Remove-Item -Force -Recurse "${CSERoot}\Packages\*" -Exclude PackageList.txt

#Invoke-Expression -Command "PowerShell -NoLogo -NoExit -File ${CSERoot}\InstallClangSetupvNext.ps1"
