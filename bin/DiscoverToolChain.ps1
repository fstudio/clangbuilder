<#############################################################################
#  DiscoverToolChain.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>
##############################################################################>
param(
    [Switch]$MSYS2
)
$SelfFolder=$PSScriptRoot;
$ClangbuilderRoot=Split-Path -Parent $SelfFolder
$PackagesPath="$ClangbuilderRoot/packages"

if($MSYS2){
    if(Test-Path "$PackagesPath/PathLoader2.ps1"){
        Invoke-Expression -Command "$PackagesPath/PathLoader2.ps1"
    }
}else{
    if(Test-Path "$PackagesPath/PathLoader.ps1"){
        Invoke-Expression -Command "$PackagesPath/PathLoader.ps1"
    }
}
