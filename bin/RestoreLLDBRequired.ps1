<#############################################################################
#  RestoreLLDBRequired.ps1
#  Note: Clang Auto Build TaskScheduler
#  Date:2016 01
#  Author:Force <forcemz@outlook.com>
##############################################################################>
Import-Module -Name BitsTransfer

# PowerShell 5.0 :Expand-Archive
Function Expend-ZipPackage
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
    Write-Host "Use System.IO.Compression.ZipFile Unzip `nPackage: $Source`nOutput: $Folder"
    [System.IO.Compression.ZipFile]::ExtractToDirectory($Source, $Folder)
}

Function Restore-Python{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter URL")]
        [ValidateNotNullorEmpty()]
        [String]$URL,
        [String]$Folder="$PSScriptRoot\Required"
    )
    Start-BitsTransfer -Source $URL -Destination "python27.zip" -Description "Downloading Python 27 sources"
    if(Test-Path "python27.zip"){
        Unblock-File -Path "python27.zip"
        Expend-ZipPackage -Source "python27.zip" -Folder $Folder
        Rename-Item "$PSScriptRoot\Required\python27-master" "$PSScriptRoot\Required\Python27"
        Remove-Item -Force "python27.zip"
    }else{
        Write-Error "Download Python 27 sources failure !"
    }
}

Function Restore-Swigwin{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter URL")]
        [ValidateNotNullorEmpty()]
        [String]$URL,
        [String]$Folder="$PSScriptRoot\Required"
    )
    Start-BitsTransfer -Source $URL -Destination "swigwin.zip" -Description "Downloading swigwin"
    if(Test-Path "swigwin.zip"){
        Unblock-File -Path "swigwin.zip"
        Expend-ZipPackage -Source "swigwin.zip" -Folder $Folder
        Rename-Item "$PSScriptRoot\Required\swigwin-3.0.8" "$PSScriptRoot\Required\swigwin"
        Remove-Item -Force "swigwin.zip"
    }else{
        Write-Error "Download swigwin failure !"
    }
}


$RequiredFolder="$PSScriptRoot\Required"
$SwigwinUrl="http://sourceforge.net/projects/swig/files/swigwin/swigwin-3.0.8/swigwin-3.0.8.zip"
$PythonUrl="https://github.com/fstudio/python27/archive/master.zip"

Push-Location $PWD
Set-Location $RequiredFolder

if(!(Test-Path "$RequiredFolder\swigwin\swig.exe")){
    Restore-Swigwin -URL $SwigwinUrl 
}

if(!(Test-Path "$RequiredFolder\Python27")){
    Restore-Python -URL $PythonUrl
}

$env:PATH=$env:PATH+";"+"$RequiredFolder"



