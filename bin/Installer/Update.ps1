<####################################################################################################################
# Clangbuilder Environment Update Module
# Date:2016.01.03
# Author:Force <forcemz@outlook.com>
####################################################################################################################>
IF($PSVersionTable.PSVersion.Major -lt 3)
{
    Write-Error "Visual Studio Enviroment vNext Must Run on Windows PowerShell 3 or Later,`nYour PowerShell version Is :
    ${Host}"
    [System.Console]::ReadKey()
    return
}

Function Expand-ZipPackage
{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Zip Sources")]
        [ValidateNotNullorEmpty()]
        [String]$ZipSource,
        [Parameter(Position=1,Mandatory=$True,HelpMessage="Output Destination")]
        [ValidateNotNullorEmpty()]
        [String]$Destination
    )
    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')|Out-Null
    Write-Output "Use System.IO.Compression.ZipFile Unzip `nPackage: $ZipSource`nOutput: $Destination"
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipSource, $Destination)
}


Function Get-GithubUpdatePackage
{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter Install Root")]
        [ValidateNotNullorEmpty()]
        [String]$Root
    )
    $ClangbuilderEnvPkUrl="https://github.com/fstudio/clangbuilder/archive/master.zip"
    $ClangbuilderEnvPkName="$env:TEMP\clangbuilder.zip"
    Start-BitsTransfer $ClangbuilderEnvPkUrl  $ClangbuilderEnvPkName
    if(!(Test-Path $ClangbuilderEnvPkName)){
        Exit
    }
    Unblock-File $ClangbuilderEnvPkName
    Expand-ZipPackage -ZipSource $ClangbuilderEnvPkName -Destination "${env:TEMP}\ClangbuilderTEMP"
    Copy-Item -Path "${Env:TEMP}\ClangbuilderTEMP\clangbuilder-master\*" $Root  -Force -Recurse
    Remove-Item -Force -Recurse "$ClangbuilderEnvPkName"
    Remove-Item -Force -Recurse "${env:TEMP}\ClangbuilderTEMP"
}

$SelfParent=Split-Path -Parent $PSScriptRoot
$ClangbuilderRoot=Split-Path -Parent $SelfParent
Set-StrictMode -Version latest
Import-Module -Name BitsTransfer

Get-GithubUpdatePackage -Root $ClangbuilderRoot
