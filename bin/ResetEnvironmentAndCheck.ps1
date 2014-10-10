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
Invoke-Expression "$REACDIR\ClangSetupEnvironmentUpdate.ps1"

