<#############################################################################################################
# ClangSetup Environment vNext Internal
#
#
##############################################################################################################>
$CSEvNInternalFd=Split-Path -Parent $MyInvocation.MyCommand.Definition
$CSEvParent=Split-Path -Parent $CSEvNInternalFd

Function Global:Add-FolderToPath([String]$MyFolder)
{
IF((Test-Path $MyFolder))
{
$env:Path="${MyFolder};${env:Path}"
return $True
}
return $False
}



IF(!(Test-Path "${CSEvParent}\Packages"))
{
Write-Host -ForegroundColor Red "ClangSetup Not Found ${CSEvParent}\Packages in your ClangSetup installation directory "
IEX "${CSEvNInternalFd}\ClangSetupvNextUI.ps1"
Get-ReadMeWindow |Out-Null
return
}
#TaskScheduler
IF((Test-Path "${CSEvParent}\Packages\NetTools"))
{
$env:Path="${env:Path};${CSEvParent}\Packages\NetTools"
}
Add-FolderToPath "${CSEvParent}\Packages\NativeTools" |Out-Null
Add-FolderToPath "${CSEvParent}\Packages\CMake\bin" |Out-Null
Add-FolderToPath "${CSEvParent}\Packages\GnuWin\bin" |Out-Null
#\Packages\SVN\
Add-FolderToPath "${CSEvParent}\Packages\SVN\bin" |Out-Null
Add-FolderToPath "${CSEvParent}\Packages\Python" |Out-Null
Add-FolderToPath "${CSEvParent}\Packages\NSIS" |Out-Null