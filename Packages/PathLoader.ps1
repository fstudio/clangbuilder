<#############################################################################
#  PathLoader.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>    
##############################################################################>
$SelfFolder=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
$CMakePath="$SelfFolder\CMake\bin"
$SubversionPath="$SelfFolder\Subversion\bin"
$OfficaPythonPath="$SelfFolder\Python"
$GNUWinPath="$SelfFolder\GNUWin\bin"
$NSISPath="$SelfFolder\NSIS\bin"


Function Test-PutPath{
param(
[String]$Path
)
if(Test-Path $Path){
$env:Path="${env:Path};$Path"
}
}

Test-PutPath -Path $CMakePath
Test-PutPath -Path $SubversionPath
Test-PutPath -Path $OfficaPythonPath
Test-PutPath -Path $NSISPath
Test-PutPath -Path $GNUWinPath
