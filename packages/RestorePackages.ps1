<#############################################################################
#  RestorePackages.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>
##############################################################################>
Set-StrictMode -Version latest
Push-Location $PWD
Set-Location $PSScriptRoot

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

Function Expand-MsiPackage{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="MSI install package")]
        [ValidateNotNullorEmpty()]
        [String]$MsiPackage,
        [Parameter(Position=1,Mandatory=$True,HelpMessage="Output Directory")]
        [ValidateNotNullorEmpty()]
        [String]$Destination
    )
    if(Test-Path $MsiPackage){
        $retValue=99
        $process=Start-Process -FilePath "msiexec" -ArgumentList "/a `"$MsiPackage`" /qn TARGETDIR=`"$Destination`""  -PassThru -WorkingDirectory "$PSScriptRoot"
        Wait-Process -InputObject $process
        $retValue=$process.ExitCode
        if($retValue -eq 0){
            Write-Host "Expand $MsiPackage success !"
            return $TRUE
        }
        Write-Error "Invoke msiexec expend package: $MsiPackage failed !"
    }else{
        Write-Error "Cannot found MSI Package: $MsiPackage"
    }
    return $FALSE
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

if(Test-Path "$PSScriptRoot/Package.lock.json"){
    $PackageLockJson=Get-Content -TotalCount -1 -Path "$PSScriptRoot/Package.lock.json" |ConvertFrom-Json
}

if($PackageLockJson -ne $null){
    if($PackageLockJson.CMake -ne $PackageMap["CMake"] -and (Test-Path "$PSScriptRoot\CMake") ){
        Rename-Item "$PSScriptRoot\CMake" "$PSScriptRoot\CMake.bak"
    }
    if($PackageLockJson.Subversion -ne $PackageMap["Subversion"] -and (Test-Path "$PSScriptRoot\Subversion")){
        Rename-Item "$PSScriptRoot\Subversion" "$PSScriptRoot\Subversion.bak"
    }
    if($PackageLockJson.Python -ne $PackageMap["Python"] -and (Test-Path "$PSScriptRoot\Python")){
        Rename-Item "$PSScriptRoot\Python" "$PSScriptRoot\Python.bak"
    }
    if($PackageLockJson.NSIS -ne $PackageMap["NSIS"] -and (Test-Path "$PSScriptRoot\NSIS")){
        Rename-Item "$PSScriptRoot\NSIS" "$PSScriptRoot\NSIS.bak"
    }
    if($PackageLockJson.GNUWin -ne $PackageMap["GNUWin"] -and (Test-Path "$PSScriptRoot\GNUWin")){
        Rename-Item "$PSScriptRoot\GNUWin" "$PSScriptRoot\GNUWin.bak"
    }
    if($PackageLockJson.Ninja -ne $PackageMap["Ninja"] -and (Test-Path "$PSScriptRoot\Ninja")){
        Rename-Item "$PSScriptRoot\Ninja" "$PSScriptRoot\Ninja.bak"
    }
}

if(!(Test-Path "$PSScriptRoot/cmake/bin/cmake.exe")){
    Write-Output "Download CMake and Unzip CMake"
    ###Restore CMake
    Start-BitsTransfer -Source $CMakeURL -Destination "$PSScriptRoot\CMake.zip" -Description "Downloading CMake"
    if(Test-Path "$PSScriptRoot\CMake.zip"){
        Unblock-File -Path "$PSScriptRoot\CMake.zip"
        Expand-ZipPackage -ZipSource "$PSScriptRoot\CMake.zip" -Destination "$PSScriptRoot"
        Rename-Item $CMakeSub "cmake"
        Remove-Item -Force -Recurse "$PSScriptRoot\CMake.zip"
    }else{
        Write-Error "Download CMake failure !"
    }
}else{
    Write-Output "CMake has been installed"
}

if(!(Test-Path "$PSScriptRoot/Python/python.exe")){
    #Restore Python
    Write-Output "Download Python27 and Install Python, Not Require Administrator."
    Start-BitsTransfer -Source $PythonURL -Destination "$PSScriptRoot\Python.msi" -Description "Downloading Python"
    if(Test-Path "$PSScriptRoot\Python.msi"){
        Unblock-File -Path "$PSScriptRoot\Python.msi"
        $pyresult=Expand-MsiPackage -MsiPackage "$PSScriptRoot\Python.msi" -Destination "$PSScriptRoot\Python"
        if($pyresult)
        {
            Remove-Item -Force -Recurse "$PSScriptRoot\Python.msi"
            Remove-Item -Force -Recurse "$PSScriptRoot\Python\Python.msi"
        }else{
            Write-Error "Unpack Python.msi failure !"
        }
    }else{
        Write-Error "Download Python.msi failure !"
    }
}else{
    Write-Output "Python has been installed"
}


if(!(Test-Path "$PSScriptRoot/Subversion/bin/svn.exe")){
    #Restore Subversion
    Write-Output "Download Subversion"
    Start-BitsTransfer -Source $SubversionURL -Destination "$PSScriptRoot\Subversion.msi" -Description "Downloading Subversion"
    if(Test-Path "$PSScriptRoot\Subversion.msi"){
        Unblock-File -Path "$PSScriptRoot\Subversion.msi"
        #Start-Process -FilePath msiexec -ArgumentList "/a `"$PSScriptRoot\Subversion.msi`" /qn TARGETDIR=`"$PSScriptRoot\Subversion`"" -NoNewWindow -Wait
        $svnResult=Expand-MsiPackage -MsiPackage "$PSScriptRoot\Subversion.msi" -Destination "$PSScriptRoot\Subversion"
        if($svnResult)
        {
            Remove-Item -Force -Recurse "$PSScriptRoot\Subversion.msi"
            Move-Item -Force "$PSScriptRoot\Subversion\Program Files\TortoiseSVN\*" "$PSScriptRoot\Subversion"
            Remove-Item -Force -Recurse "$PSScriptRoot\Subversion\Program Files"
            Remove-Item -Force -Recurse "$PSScriptRoot\Subversion\Subversion.msi"
        }else{
            Write-Error "Unpack Subversion.msi failure !"
        }
    }else{
        Write-Error "Download Subversion failure !"
    }
}else{
    Write-Output "Subversion has been installed"
}

if(!(Test-Path "$PSScriptRoot/nsis/NSIS.exe")){
    #Restore NSIS
    Write-Output "Download NSIS and Unzip NSIS"
    Start-BitsTransfer -Source $NSISURL -Destination "$PSScriptRoot\NSIS.zip" -Description "Downloading NSIS"
    if(Test-Path "$PSScriptRoot\NSIS.zip"){
        Unblock-File -Path "$PSScriptRoot\NSIS.zip"
        Expand-ZipPackage -ZipSource "$PSScriptRoot\NSIS.zip" -Destination "$PSScriptRoot"
        Rename-Item $NSISSub "nsis"
    }else{
        Write-Error "Download NSIS failure !"
    }
}else{
    Write-Output "NSIS has been installed"
}

if(!(Test-Path "$PSScriptRoot\GNUWin\bin\grep.exe")){
    #Restore GNUWin
    Write-Output "Download GNUWin tools and Unzip it."
    Start-BitsTransfer -Source $GnuWinURL -Destination "$PSScriptRoot\GNUWin.zip" -Description "Downloading GNUWin"
    if(Test-Path "$PSScriptRoot\GNUWin.zip"){
        Unblock-File -Path "$PSScriptRoot\GNUWin.zip"
        Expand-ZipPackage -ZipSource "$PSScriptRoot\GNUWin.zip" -Destination "$PSScriptRoot\GNUWin"
    }else{
        Write-Error "Download GNUWin tools failure !"
    }
}else{
    Write-Output  "GNUWin has been installed"
}

if(!(Test-Path "$PSScriptRoot\Ninja\ninja.exe")){
    Write-Output "Download Ninja-build utility now"
    #Start-BitsTransfer -Source $NinjaURL -Destination "$PSScriptRoot\Ninja.zip" -Description "Downloading Ninja-build"
     Invoke-WebRequest $NinjaURL -OutFile "$PSScriptRoot/Ninja.zip"
    if(Test-Path "$PSScriptRoot\Ninja.zip"){
        Unblock-File -Path "$PSScriptRoot\Ninja.zip"
        Expand-ZipPackage -ZipSource "$PSScriptRoot\Ninja.zip" -Destination "$PSScriptRoot\Ninja"
    }else{
        Write-Error "Download Ninja tools failure !"
    }
}else{
    Write-Output  "ninja-build has been installed"
}

##Check Package
if(!(Test-Path "$PSScriptRoot\CMake")){
    if(Test-Path "$PSScriptRoot\CMake.bak"){
        Rename-Item "$PSScriptRoot\CMake.bak" "$PSScriptRoot\CMake"
    }
}

if(!(Test-Path "$PSScriptRoot\Python")){
    if(Test-Path "$PSScriptRoot\Python.bak"){
        Rename-Item "$PSScriptRoot\Python.bak" "$PSScriptRoot\Python"
    }
}

if(!(Test-Path "$PSScriptRoot\Subversion")){
    if(Test-Path "$PSScriptRoot\Subversion.bak"){
        Rename-Item "$PSScriptRoot\Subversion.bak" "$PSScriptRoot\Subversion"
    }
}

if(!(Test-Path "$PSScriptRoot\NSIS")){
    if(Test-Path "$PSScriptRoot\NSIS.bak"){
        Rename-Item "$PSScriptRoot\NSIS.bak" "$PSScriptRoot\NSIS"
    }
}

if(!(Test-Path "$PSScriptRoot\GNUWin")){
    if(Test-Path "$PSScriptRoot\GNUWin.bak"){
        Rename-Item "$PSScriptRoot\GNUWin.bak" "$PSScriptRoot\GNUWin"
    }
}

if(!(Test-Path "$PSScriptRoot\Ninja")){
    if(Test-Path "$PSScriptRoot\Ninja.bak"){
        Rename-Item "$PSScriptRoot\Ninja.bak" "$PSScriptRoot\Ninja"
    }
}


Remove-Item -Recurse -Force "$PSScriptRoot\*.bak"
Remove-Item -Recurse -Force "$PSScriptRoot\*.zip"

##Write Lock File
ConvertTo-Json $PackageMap |Out-File -Force -FilePath "$PSScriptRoot\Package.lock.json"

Pop-Location
Write-Output "Your can Load PathLoader to Setting Your Clangbuilder Environment"
