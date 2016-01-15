<#############################################################################
#  RestorePackages.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>
##############################################################################>
Set-StrictMode -Version latest
$SelfFolder=$PSScriptRoot;
Push-Location $PWD
Set-Location $SelfFolder

Import-Module -Name BitsTransfer
$IsWindows64=[System.Environment]::Is64BitOperatingSystem

$CMakeURL="https://cmake.org/files/v3.4/cmake-3.4.1-win32-x86.zip"
$CMakeSub="cmake-3.4.1-win32-x86"
if($IsWindows64){
$PythonURL="https://www.python.org/ftp/python/2.7.11/python-2.7.11.amd64.msi"
$SubversionURL="http://sourceforge.net/projects/tortoisesvn/files/1.9.3/Application/TortoiseSVN-1.9.3.27038-x64-svn-1.9.3.msi"
}else{
$PythonURL="https://www.python.org/ftp/python/2.7.11/python-2.7.11.msi"
$SubversionURL="https://sourceforge.net/projects/tortoisesvn/files/1.9.3/Application/TortoiseSVN-1.9.3.27038-win32-svn-1.9.3.msi"
}
$NSISURL="http://sourceforge.net/projects/nsis/files/NSIS%203%20Pre-release/3.0b3/nsis-3.0b3.zip"
$NSISSub="nsis-3.0b3"

$GnuWinURL="http://sourceforge.net/projects/clangonwin/files/Install/Packages/ClangSetup-Package-GnuWin-win32.zip"

<#$CMakeLock="3.4.1"
$SubversionLock="1.9.3"
$PythonLock="2.7.11"
$NSISLock="3.0b3"
$GnuWinLock="1.0"
#>

Function Expand-ZipPackage
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
[System.IO.Compression.ZipFile]::ExtractToDirectory($ZipSource, $Destination)
}



if(!(Test-Path "$SelfFolder/cmake/bin/cmake.exe")){
Write-Output "Download CMake and Unzip CMake"
###Restore CMake
Start-BitsTransfer -Source $CMakeURL -Destination "$SelfFolder\CMake.zip" -Description "Downloading CMake"
if(Test-Path "$SelfFolder\CMake.zip"){
Unblock-File -Path "$SelfFolder\CMake.zip"
Expand-ZipPackage -ZipSource "$SelfFolder\CMake.zip" -Destination "$SelfFolder"
Rename-Item $CMakeSub "cmake"
Remove-Item -Force -Recurse "$SelfFolder\CMake.zip"
}
}else{
Write-Output "CMake has been installed"
}

if(!(Test-Path "$SelfFolder/Python/python.exe")){
#Restore Python
Write-Output "Download Python27 and Install Python, Not Require Administrator."
Start-BitsTransfer -Source $PythonURL -Destination "$SelfFolder\Python.msi" -Description "Downloading Python"
if(Test-Path "$SelfFolder\Python.msi"){
Unblock-File -Path "$SelfFolder\Python.msi"
Start-Process -FilePath msiexec -ArgumentList "/a `"$SelfFolder\Python.msi`" /qn TARGETDIR=`"$SelfFolder\Python`"" -NoNewWindow -Wait
if($? -eq $True)
{
   Remove-Item -Force -Recurse "$SelfFolder\Python.msi"
   Remove-Item -Force -Recurse "$SelfFolder\Python\Python.msi"
}
}
}else{
Write-Output "Python has been installed"
}

if(!(Test-Path "$SelfFolder/Subversion/bin/svn.exe")){
#Restore Subversion
Write-Output "Download Subversion"
Start-BitsTransfer -Source $SubversionURL -Destination "$SelfFolder\Subversion.msi" -Description "Downloading Subversion"
if(Test-Path "$SelfFolder\Subversion.msi"){
Unblock-File -Path "$SelfFolder\Subversion.msi"
Start-Process -FilePath msiexec -ArgumentList "/a `"$SelfFolder\Subversion.msi`" /qn TARGETDIR=`"$SelfFolder\Subversion`"" -NoNewWindow -Wait
if($? -eq $True)
{
   Remove-Item -Force -Recurse "$SelfFolder\Subversion.msi"
   Move-Item -Force "$SelfFolder\Subversion\Program Files\TortoiseSVN\*" "$SelfFolder\Subversion"
   Remove-Item -Force -Recurse "$SelfFolder\Subversion\Program Files"
   Remove-Item -Force -Recurse "$SelfFolder\Subversion\Subversion.msi"
}
}
}else{
Write-Output "Subversion has been installed"
}

if(!(Test-Path "$SelfFolder/nsis/NSIS.exe")){
#Restore NSIS
Write-Output "Download NSIS and Unzip NSIS"
Start-BitsTransfer -Source $NSISURL -Destination "$SelfFolder\NSIS.zip" -Description "Downloading NSIS"
if(Test-Path "$SelfFolder\NSIS.zip"){
Unblock-File -Path "$SelfFolder\NSIS.zip"
Unzip-Package -ZipSource "$SelfFolder\NSIS.zip" -Destination "."
Rename-Item $NSISSub "nsis"
}
}else{
Write-Output "NSIS has been installed"
}

if(!(Test-Path "$SelfFolder/GNUWin/bin/grep.exe")){
#Restore GNUWin
Write-Output "Download GNUWin tools and Unzip it."
Start-BitsTransfer -Source $GnuWinURL -Destination "$SelfFolder\GNUWin.zip" -Description "Downloading GNUWin"
if(Test-Path "$SelfFolder\GNUWin.zip"){
Unblock-File -Path "$SelfFolder\GNUWin.zip"
Unzip-Package -ZipSource "$SelfFolder\GNUWin.zip" -Destination "GNUWin"
}
}else{
Write-Output  "GNUWin has been installed"
}

Pop-Location

Write-Output "Your can Load PathLoader to Setting Your Clangbuilder Environment"
