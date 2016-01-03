<#############################################################################
#  Install.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.03
#  Author:Force <forcemz@outlook.com>    
##############################################################################>
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


Invoke-Expression -Command "$ClangbuilderRoot/tools/RestoreUtilitytools.ps1"

if($args.Count -ge 1){
$args | foreach{
if($_ -eq "-Reset"){
Remove-Item -Recurse -Force "$ClangbuilderRoot/Packages/*" -Exclude "*.ps1"
}
}
}
Invoke-Expression -Command "$ClangbuilderRoot/Packages/RestorePackages.ps1"
