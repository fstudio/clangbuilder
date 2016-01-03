<#############################################################################
#  RestoreLLDBRequired.ps1
#  Note: Clang Auto Build TaskScheduler
#  Date:2016 01
#  Author:Force <forcemz@outlook.com>    
##############################################################################>
$SelfFolder=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
Import-Module -Name BitsTransfer

Function Unzip-Package
{
param(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Unzip sources")]
[ValidateNotNullorEmpty()]
[String]$Source,
[Parameter(Position=1,Mandatory=$True,HelpMessage="Output Directory")]
[ValidateNotNullorEmpty()]
[String]$Folder
)
[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')|Out-Null
Write-Host "Use System.IO.Compression.ZipFile Unzip ¡¤nPackage: $Source`nOutput: $Folder"
[System.IO.Compression.ZipFile]::ExtractToDirectory($Source, $Folder)
}

Function Get-SWigWIN{
$SWIGWINURL="http://sourceforge.net/projects/swig/files/swigwin/swigwin-3.0.8/swigwin-3.0.8.zip"
Start-BitsTransfer -Source $SWIGWINURL -Destination "$SelfFolder\Required\swigwin.zip" -Description "Downloading swigwin"
if(Test-Path "$SelfFolder\Required\swigwin.zip"){
    Unblock-File -Path "$SelfFolder\Required\swigwin.zip"
    Unzip-Package -Source "$SelfFolder\Required\swigwin.zip" -Folder "$SelfFolder\Required"
    Rename-Item "$SelfFolder\Required\swigwin-3.0.8" "$SelfFolder\Required\swigwin"
}

}

Get-SWigWIN