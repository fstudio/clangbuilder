<#############################################################################
#  ClangBuilderEnvironmnet.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>    
##############################################################################>
if($PSVersionTable.PSVersion.Major -lt 3)
{
    $PSVersionString=$PSVersionTable.PSVersion.Major
    Write-Host -ForegroundColor Red "Clangbuilder must run under PowerShell 3.0 or later host environment !"
    Write-Host -ForegroundColor Red "Your PowerShell Version:$PSVersionString"
    if($Host.Name -eq "ConsoleHost"){
        [System.Console]::ReadKey()
    }
    Exit
}
$WindowTitlePrefix="Clangbuilder PowerShell Utility"
Write-Host "Clang Auto Builder [PowerShell] Utility tools"
Write-Host "Copyright $([Char]0xA9) 2016. FroceStudio. All Rights Reserved."

$SelfFolder=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)

Import-Module "$SelfFolder/ClangBuilderUtility.ps1"

$UseClearEnv=$False
$Target="x64"
$VisualStudioVersion=120

if($args.Count -ge 1){
$args | foreach {
$va=$_
if($va -eq "-Clear"){
$UseClearEnv=$True
}
#
if($va -match "-V\d+"){
if($va -eq "-V110"){
$VisualStudioVersion=110
}elseif($va -eq "-V120"){
$VisualStudioVersion=120
}elseif($va -eq "-V140"){
$VisualStudioVersion=140
}elseif($va -eq "-V141"){
$VisualStudioVersion=141
}elseif($va -eq "-V150"){
$VisualStudioVersion=150
}ELSE{
Write-Host -ForegroundColor Red "Unknown VisualStudio Version: $va"
}
}
#
if($va -match "-T\w+"){
if($va -eq "-Tx86"){
$Target="x86"
}elseif($va -eq "-Tx64"){
$Target="x64"
}elseif($va -eq "-TARM"){
$Target="ARM"
}elseif($va -eq "-TARM64"){
$Target="ARM64"
}ELSE{
Write-Host -ForegroundColor Red "Unknown Target: $va"
Exit
}
}
#
}
#
}

if($UseClearEnv){
    Clear-Environment
}

Invoke-Expression -Command "$SelfFolder/Model/VisualStudioSub$VisualStudioVersion.ps1 $Target"
Invoke-Expression -Command "$SelfFolder/DiscoverToolChain.ps1"

Write-Host "Clangbuilder Environment Set done
Visual Studio $VisualStudioVersion Target $Target
V110 - VisualStudio 2012
V120 - VisualStudio 2013
V140 - VisualStudio 2015 Windows 8.1 SDK
V141 - VisualStudio 2015 Windows 10 SDK
"
