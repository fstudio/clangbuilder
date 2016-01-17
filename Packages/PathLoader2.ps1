<#############################################################################
#  PathLoader2.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.0115
#  Author:Force <forcemz@outlook.com>
##############################################################################>

$SelfFolder=$PSScriptRoot;
$CMakePath="$SelfFolder\CMake\bin"
$SubversionPath="$SelfFolder\Subversion\bin"
$OfficaPythonPath="$SelfFolder\Python"
#$GNUWinPath="$SelfFolder\GNUWin\bin"
$NSISPath="$SelfFolder\NSIS\bin"

Function Test-AddPath{
    param(
        [String]$Path
    )
    if(Test-Path $Path){
        $env:Path="$Path;${env:Path}"
    }
}

Test-AddPath -Path $CMakePath
Test-AddPath -Path $SubversionPath
Test-AddPath -Path $OfficaPythonPath
Test-AddPath -Path $NSISPath
#Test-AddPath -Path $GNUWinPath

if(!(Test-Path "$PSScriptRoot\PackageStore.json")){
    Write-Error "Cannot Found PackageStore.json in $PSScriptRoot"
    return 
}

$PackageStoreList=(Get-Content "$PSScriptRoot\PackageStore.json") -join "`n" | ConvertFrom-Json

if($null -ne $PackageStoreList.MSYS2){
    Test-AddPath -Path $PackageStoreList.MSYS2
}

