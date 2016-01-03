<#############################################################################
#  Install.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.03
#  Author:Force <forcemz@outlook.com>    
##############################################################################>
IF($PSVersionTable.PSVersion.Major -lt 3)
{
Write-Host -ForegroundColor Red "Visual Studio Enviroment vNext Must Run on Windows PowerShell 3 or Later,`nYour PowerShell version Is : 
${Host}"
[System.Console]::ReadKey()
return 
}

$SelfFolder=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
$SelfParent=Split-Path -Parent $SelfFolder
$ClangbuilderRoot=Split-Path -Parent $SelfParent

Invoke-Expression -Command "$ClangbuilderRoot/Packages/RestorePackages.ps1"
Invoke-Expression -Command "$ClangbuilderRoot/tools/RestoreUtilitytools.ps1"

Function Install-Clangbuilder{

if(!(Test-Path "$ClangbuilderRoot/Packages/cmake/bin/cmake.exe")){
Install-CMake
}

if(!(Test-Path "$ClangbuilderRoot/Packages/Python/python.exe")){
Install-Python
}

if(!(Test-Path "$ClangbuilderRoot/Packages/Subversion/bin/svn.exe")){
Install-Subversion
}

if(!(Test-Path "$ClangbuilderRoot/Packages/nsis/NSIS.exe")){
Install-NSIS
}

if(!(Test-Path "$ClangbuilderRoot/Packages/GNUWin/bin/grep.exe")){
Install-GNUWin
}

}

Function Reset-Clangbuilder{
Remove-Item -Recurse -Force "$ClangbuilderRoot/Packages/*" -Exclude "*.ps1"
Install-CMake
Install-Python
Install-Subversion
Install-NSIS
Install-GNUWin
}


if($args.Count -ge 1){
$args | foreach{
if($_ -eq "-Reset"){
Reset-Clangbuilder
}else{
Install-Clangbuilder
}
}
}
