<#############################################################################################################
# ClangSetup Environment vNext
#
#
##############################################################################################################>
IF($PSVersionTable.PSVersion.Major -lt 3)
{
Write-Host -ForegroundColor Red "ClangSetup Enviroment vNext Must Run on Windows PowerShell 3 or Later,`nYour PowerShell version Is : 
${Host}"
[System.Console]::ReadKey()
Exit
}

$CSEvNInvoke=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
Set-Location $CSEvNInvoke
IEX "${CSEvNInvoke}\bin\ClangSetupvNextUI.ps1"
IEX "${CSEvNInvoke}\bin\CSEvNInternal.ps1"
Show-LauncherWindow

Function Global:Check-Environment()
{

}

#Show-OpenFileDialog
