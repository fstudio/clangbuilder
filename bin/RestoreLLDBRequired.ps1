<#############################################################################
#  RestoreLLDBRequired.ps1
#  Note: Clang Auto Build TaskScheduler
#  Date:2016 01
#  Author:Force <forcemz@outlook.com>
##############################################################################>
Import-Module -Name BitsTransfer
# See http://lldb.llvm.org/build.html#BuildingLldbOnWindows
# PowerShell 5.0 :Expand-Archive
Function Expand-ZipPackage
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
        Expand-ZipPackage -Source "swigwin.zip" -Folder $Folder
        Rename-Item "$PSScriptRoot\Required\swigwin-3.0.8" "$PSScriptRoot\Required\swigwin"
        Remove-Item -Force "swigwin.zip"
    }else{
        Write-Error "Download swigwin failure !"
    }
}


$RequiredFolder="$PSScriptRoot\Required"
$SwigwinUrl="http://sourceforge.net/projects/swig/files/swigwin/swigwin-3.0.8/swigwin-3.0.8.zip"
$PythonUrl64="https://www.python.org/ftp/python/3.5.1/python-3.5.1-amd64.exe"
$PTVSUrl="https://ptvs.blob.core.windows.net/download/PTVS%20Dev%202016-03-03%20VS%202015.msi"

Push-Location $PWD
Set-Location $RequiredFolder

if(!(Test-Path "$RequiredFolder\swigwin\swig.exe")){
    Restore-Swigwin -URL $SwigwinUrl 
}



