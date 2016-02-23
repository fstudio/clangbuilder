<#############################################################################
#  PathLoader.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>
##############################################################################>
$CMakePath="$PSScriptRoot\CMake\bin"
$SubversionPath="$PSScriptRoot\Subversion\bin"
$OfficaPythonPath="$PSScriptRoot\Python"
$GNUWinPath="$PSScriptRoot\GNUWin\bin"
$NSISPath="$PSScriptRoot\NSIS\bin"
$NinjaPath="$PSScriptRoot\Ninja"

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
Test-AddPath -Path $GNUWinPath
Test-AddPath -Path $NinjaPath
