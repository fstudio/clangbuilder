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

Import-Module -Name BitsTransfer
$IsWindows64=[System.Environment]::Is64BitOperatingSystem

$CMakeURL="https://cmake.org/files/v3.4/cmake-3.4.2-win32-x86.zip"
$CMakeSub="cmake-3.4.2-win32-x86"

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

$NinjaURL="https://github.com/ninja-build/ninja/releases/download/v1.6.0/ninja-win.zip"


$PackageMap=@{}
$PackageMap["CMake"]="3.4.2"
$PackageMap["Subversion"]="1.9.3"
$PackageMap["Python"]="2.7.11"
$PackageMap["NSIS"]="3.0b3"
$PackageMap["GNUWin"]="1.0"
$PackageMap["Ninja"]="1.6.0"

#### Test Package.lock.json
$PackageLockJson=$null
#$PackageLockJsonNew=ConvertTo-Json $PackageMap|ConvertFrom-Json

if(Test-Path "$SelfFolder/Package.lock.json"){
    $PackageLockJson=Get-Content -TotalCount -1 -Path "$SelfFolder/Package.lock.json" |ConvertFrom-Json
}

if($PackageLockJson -ne $null){
    if($PackageLockJson.CMake -ne $PackageMap["CMake"] -and (Test-Path "$SelfFolder\CMake") ){
        Rename-Item "$SelfFolder\CMake" "$SelfFolder\CMake.bak"
    }
    if($PackageLockJson.Subversion -ne $PackageMap["Subversion"] -and (Test-Path "$SelfFolder\Subversion")){
        Rename-Item "$SelfFolder\Subversion" "$SelfFolder\Subversion.bak"
    }
    if($PackageLockJson.Python -ne $PackageMap["Python"] -and (Test-Path "$SelfFolder\Python")){
        Rename-Item "$SelfFolder\Python" "$SelfFolder\Python.bak"
    }
    if($PackageLockJson.NSIS -ne $PackageMap["NSIS"] -and (Test-Path "$SelfFolder\NSIS")){
        Rename-Item "$SelfFolder\NSIS" "$SelfFolder\NSIS.bak"
    }
    if($PackageLockJson.GNUWin -ne $PackageMap["GNUWin"] -and (Test-Path "$SelfFolder\GNUWin")){
        Rename-Item "$SelfFolder\GNUWin" "$SelfFolder\GNUWin.bak"
    }
    if($PackageLockJson.Ninja -ne $PackageMap["Ninja"] -and (Test-Path "$SelfFolder\Ninja")){
        Rename-Item "$SelfFolder\Ninja" "$SelfFolder\Ninja.bak"
    }
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
    }else{
        Write-Error "Download CMake failure !"
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
        if($lastexitcode -eq 0)
        {
            Remove-Item -Force -Recurse "$SelfFolder\Python.msi"
            Remove-Item -Force -Recurse "$SelfFolder\Python\Python.msi"
        }else{
            Write-Error "Unpack Python.msi failure !"
        }
    }else{
        Write-Error "Download Python.msi failure !"
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
        if($lastexitcode -eq 0)
        {
            Remove-Item -Force -Recurse "$SelfFolder\Subversion.msi"
            Move-Item -Force "$SelfFolder\Subversion\Program Files\TortoiseSVN\*" "$SelfFolder\Subversion"
            Remove-Item -Force -Recurse "$SelfFolder\Subversion\Program Files"
            Remove-Item -Force -Recurse "$SelfFolder\Subversion\Subversion.msi"
        }else{
            Write-Error "Unpack Subversion.msi failure !"
        }
    }else{
        Write-Error "Download Subversion failure !"
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
        Expand-ZipPackage -ZipSource "$SelfFolder\NSIS.zip" -Destination "$SelfFolder"
        Rename-Item $NSISSub "nsis"
    }else{
        Write-Error "Download NSIS failure !"
    }
}else{
    Write-Output "NSIS has been installed"
}

if(!(Test-Path "$SelfFolder\GNUWin\bin\grep.exe")){
    #Restore GNUWin
    Write-Output "Download GNUWin tools and Unzip it."
    Start-BitsTransfer -Source $GnuWinURL -Destination "$SelfFolder\GNUWin.zip" -Description "Downloading GNUWin"
    if(Test-Path "$SelfFolder\GNUWin.zip"){
        Unblock-File -Path "$SelfFolder\GNUWin.zip"
        Expand-ZipPackage -ZipSource "$SelfFolder\GNUWin.zip" -Destination "$SelfFolder\GNUWin"
    }else{
        Write-Error "Download GNUWin tools failure !"
    }
}else{
    Write-Output  "GNUWin has been installed"
}

if(!(Test-Path "$SelfFolder\Ninja\ninja.exe")){
    Write-Output "Download Ninja-build utility now"
    Start-BitsTransfer -Source $NinjaURL -Destination "$SelfFolder\Ninja.zip" -Description "Downloading Ninja-build"
    if(Test-Path "$SelfFolder\Ninja.zip"){
        Unblock-File -Path "$SelfFolder\Ninja.zip"
        Expand-ZipPackage -ZipSource "$SelfFolder\Ninja.zip" -Destination "$SelfFolder\Ninja"
    }else{
        Write-Error "Download Ninja tools failure !"
    }
}else{
    Write-Output  "ninja-build has been installed"
}

##Check Package
if(!(Test-Path "$SelfFolder\CMake")){
    if(Test-Path "$SelfFolder\CMake.bak"){
        Rename-Item "$SelfFolder\CMake.bak" "$SelfFolder\CMake"
    }
}

if(!(Test-Path "$SelfFolder\Python")){
    if(Test-Path "$SelfFolder\Python.bak"){
        Rename-Item "$SelfFolder\Python.bak" "$SelfFolder\Python"
    }
}

if(!(Test-Path "$SelfFolder\Subversion")){
    if(Test-Path "$SelfFolder\Subversion.bak"){
        Rename-Item "$SelfFolder\Subversion.bak" "$SelfFolder\Subversion"
    }
}

if(!(Test-Path "$SelfFolder\NSIS")){
    if(Test-Path "$SelfFolder\NSIS.bak"){
        Rename-Item "$SelfFolder\NSIS.bak" "$SelfFolder\NSIS"
    }
}

if(!(Test-Path "$SelfFolder\GNUWin")){
    if(Test-Path "$SelfFolder\GNUWin.bak"){
        Rename-Item "$SelfFolder\GNUWin.bak" "$SelfFolder\GNUWin"
    }
}

if(!(Test-Path "$SelfFolder\Ninja")){
    if(Test-Path "$SelfFolder\Ninja.bak"){
        Rename-Item "$SelfFolder\Ninja.bak" "$SelfFolder\Ninja"
    }
}


Remove-Item -Recurse -Force "$SelfFolder\*.bak"

##Write Lock File
ConvertTo-Json $PackageMap |Out-File -Force -FilePath "$SelfFolder\Package.lock.json"

Pop-Location
Write-Output "Your can Load PathLoader to Setting Your Clangbuilder Environment"
