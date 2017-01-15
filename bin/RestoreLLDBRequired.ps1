<#############################################################################
#  RestoreLLDBRequired.ps1
#  Note: Clang Auto Build TaskScheduler
#  Date:2016 01
#  Author:Force <forcemz@outlook.com>
##############################################################################>
param (
    [ValidateSet("x86", "x64")]
    [String]$Arch="x64"
)
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

Function Start-InstallPython{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter URL")]
        [ValidateNotNullorEmpty()]
        [String]$URL,
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Install Target Dir")]
        [ValidateNotNullorEmpty()]
        [String]$TargetDir
    )
    Start-BitsTransfer -Source $URL -Destination "python-install.exe" -Description "Downloading Python"
    Unblock-File -Path "python-install.exe"
    $retValue=99
    $process=Start-Process -FilePath "python-install.exe" -ArgumentList "TargetDir=`'$TargetDir`'"  -PassThru -WorkingDirectory "$PSScriptRoot"
    Wait-Process -InputObject $process
    $retValue=$process.ExitCode
    Remove-Item -Force "python-install.exe"
    if($retValue -eq 0){
        Write-Host "install python success"
        return $TRUE
    }
    Write-Error "install python failed !" 
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
$SwigwinUrl="http://sourceforge.net/projects/swig/files/swigwin/swigwin-3.0.11/swigwin-3.0.11.zip"
$PythonUrl64="https://www.python.org/ftp/python/3.6.0/python-3.6.0-amd64.exe"
$PythonUrl32="https://www.python.org/ftp/python/3.6.0/python-3.6.0.exe"
#https://docs.python.org/3.5/using/windows.html
#CMAKE -DPYTHON_HOME=$PSScriptRoot/Python$Arch

Push-Location $PWD
Set-Location $RequiredFolder

if(!(Test-Path "$RequiredFolder\swigwin\swig.exe")){
    Restore-Swigwin -URL $SwigwinUrl 
}

if(Test-Path "$RequiredFolder\swigwin\swig.exe"){
    $env:Path="$RequiredFolder\swigwin;${env:Path}"
}

$IsWin64=[System.Environment]::Is64BitOperatingSystem
$PythonRegKey="HKCU:\SOFTWARE\Python\PythonCore\3.6\InstallPath"
if($IsWin64 -and ($Arch -eq "x86")){
    $PythonRegKey="HKCU:\SOFTWARE\Python\PythonCore\3.6-32\InstallPath"    
}

if(!(Test-Path $PythonRegKey)){
    if($Arch -eq "x64"){
        Start-InstallPython -URL $PythonUrl64 -TargetDir "Python64"
    }elseif($Arch -eq "x86"){
        Start-InstallPython -URL $PythonUrl32 -TargetDir "Python32"
    }else{
        exit
    }
}

