<##
# ClangSetup ScheduledJob Manager
##>
$PSTaskBinPath=Split-Path -Parent $MyInvocation.MyCommand.Definition
$env:PSModulePath="$env:PSModulePath;${PSTaskBinPath}\Modules"

IF($PSVersionTable.PSVersion.Major -lt 3)
{
Write-Host -ForegroundColor Red "Visual Studio Enviroment vNext Must Run on Windows PowerShell 3 or Later,`nYour PowerShell version Is : 
${Host}"
[System.Console]::ReadKey()
return 
}
Import-Module TaskScheduler
<#
ClangSetupPSScheduledJob.ps1  -MakeTask -Days 10 
ClangSetupPSScheduledJob.ps1  -DeleteTask
#>
$IsMakeSdTask=$False
$IsDeleteSdTask=$False
