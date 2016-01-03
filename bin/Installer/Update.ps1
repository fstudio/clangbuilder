<####################################################################################################################
# Clangbuilder Environment Update Module
# Date:2016.01.03
# Author:Force <forcemz@outlook.com>    
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
Set-StrictMode -Version latest
Import-Module -Name BitsTransfer

Function Unzip-Package
{
param(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Unzip sources")]
[ValidateNotNullorEmpty()]
[String]$ZipSource,
[Parameter(Position=1,Mandatory=$True,HelpMessage="Output Directory")]
[ValidateNotNullorEmpty()]
[String]$Destination
)
[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')|Out-Null
Write-Host "Use System.IO.Compression.ZipFile Unzip `nPackage: $ZipSource`nOutput: $Destination"
[System.IO.Compression.ZipFile]::ExtractToDirectory($ZipSource, $Destination)
}


Function Global:Get-GithubUpdatePackage
{
param(
[String]$Root
)
if($Root -eq $null){
$Root=[String]$ClangbuilderRoot
}
 $ClangbuilderEnvPkUrl="https://github.com/fstudio/clangbuilder/archive/master.zip"
 $ClangbuilderEnvPkName="$env:TEMP\clangbuilder.zip"
 Start-BitsTransfer $ClangbuilderEnvPkUrl  $ClangbuilderEnvPkName 
 if(!(Test-Path $ClangbuilderEnvPkName)){
 Exit
 }
 Unblock-File $ClangbuilderEnvPkName
 Unzip-Package -ZipSource $ClangbuilderEnvPkName -Destination "${env:TEMP}\ClangbuilderTEMP"
 Copy-Item -Path "${Env:TEMP}\ClangbuilderTEMP\clangbuilder-master\*" $ClangbuilderRoot  -Force -Recurse
 Remove-Item -Force -Recurse "$ClangbuilderEnvPkName"
 Remove-Item -Force -Recurse "${env:TEMP}\ClangbuilderTEMP"
}

Get-GithubUpdatePackage -Root $ClangbuilderRoot

