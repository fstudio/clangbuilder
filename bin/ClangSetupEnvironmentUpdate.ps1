<####################################################################################################################
# ClangSetup Environment Update Module
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

Set-StrictMode -Version latest
Import-Module -Name BitsTransfer

Function Global:Shell-UnZip($fileName, $sourcePath, $destinationPath)
{
    $shell = New-Object -com Shell.Application
    if (!(Test-Path "$sourcePath\$fileName"))
    {
        throw "$sourcePath\$fileName does not exist" 
    }
    New-Item -ItemType Directory -Force -Path $destinationPath -WarningAction SilentlyContinue
    $shell.namespace($destinationPath).copyhere($shell.namespace("$sourcePath\$fileName").items()) 
}



Function Global:Get-GithubUpdatePackage([String]$clangsetuproot)
{
 $ClangSetupEnvPkUrl="https://github.com/fstudio/clangbuilder/archive/master.zip"
 $ClangSetupEnvPkName="$env:TEMP\ClangSetupvNextUpdatePackage.zip"
 Start-BitsTransfer $ClangSetupEnvPkUrl  $ClangSetupEnvPkName 
 Unblock-File $ClangSetupEnvPkName
 Shell-UnZip "ClangSetupvNextUpdatePackage.zip" "${env:TEMP}" "${Env:TEMP}\ClangSetupUnZipTemp"
 Copy-Item -Path "${Env:TEMP}\ClangSetupUnZipTemp\ClangSetupvNext-master\*" $clangsetuproot  -Force -Recurse
 Remove-Item -Force -Recurse "$env:TEMP\ClangSetupvNextUpdatePackage.zip"
 Remove-Item -Force -Recurse "$env:TEMP\ClangSetupUnZipTemp"
}
