<#############################################################################
#  VisualStudioSub110.ps1
#  Note: Clang Auto Build Environment for Visual Studio 2012 [Windows 8]
#  Date:2016.01.01
#  Author:Force <forcemz@outlook.com>    
##############################################################################>
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch="x64"
)

IF($PSVersionTable.PSVersion.Major -lt 3)
{
Write-Output -ForegroundColor Red "Clangbuilder Enviroment  Must Run on Windows PowerShell 3 or Later
Your PowerShell version Is :${Host}"
[System.Console]::ReadKey()
Exit
}

IF( $env:VS110COMNTOOLS -eq $null -or (Test-Path $env:VS110COMNTOOLS) -eq $false)
{
  Write-Output -ForegroundColor Red "Not Fond Vaild Install for Visual Studio 2012"
  Exit 
}

IF($Arch -eq "x86"){
    $target=1
}
IF($Arch -eq "x64"){
    $target=2
}
IF($Arch -eq "arm"){
    $target=3
}
IF($Arch -eq "arm64"){
    Write-Output -ForegroundColor Red "Visual Studio 2012 not support ARM64"
    Exit
}

$InvokerDir=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
IEX "$InvokerDir/VisualStudioShared.ps1"

IF(${env:ProgramFiles(x86)} -eq $null){
   $SystemType=32
   $ProgramDir=${env:ProgramFiles}
}ELSE{
   $SystemType=64
   $ProgramDir=${env:ProgramFiles(x86)}
}

IF($SystemType -eq 64)
{
    $VSInstall=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VS7' '11.0'
    $VCDir=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7' '11.0'
    $SDKDIR=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v8.0' 'InstallationFolder'
    $NetTools=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v8.0A\WinSDK-NetFx40Tools-x64' 'InstallationFolder'
    $FrameworkDir=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7' 'FrameworkDir64'
    $FrameworkVer=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7' 'FrameworkVer64'
    IF((Test-Path  'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\11.0\Setup\F#')){
    $FSharpDir=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\11.0\Setup\F#' 'ProductDir'
    }
}ELSE{
    $VSInstall=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VS7' '11.0'
    $VCDir=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VC7' '11.0'
    $SDKDIR=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v8.0' 'InstallationFolder'
    $NetTools=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v8.0A\WinSDK-NetFx40Tools' 'InstallationFolder'
    $FrameworkDir=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VC7' 'FrameworkDir32'
    $FrameworkVer=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VC7' 'FrameworkVer32'
    IF((Test-Path  'HKLM:\SOFTWARE\Microsoft\VisualStudio\11.0\Setup\F#')){
    $FSharpDir=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\VisualStudio\11.0\Setup\F#' 'ProductDir'
    }
}

IF($FSharpDir -eq $null)
{
    $env:Path="$NetTools;${FrameworkDir}${FrameworkVer};$env:Path"
}ELSE{
    $env:Path="$FSharpDir;$NetTools;${FrameworkDir}${FrameworkVer};$env:Path"
}

$IDE="${env:VS110COMNTOOLS}..\IDE"
$KitBin32="${SDKDIR}bin\x86"
$kitBin64="${SDKDIR}bin\amd64"
$KitBinARM="${SDKDIR}bin\ARM"
$KitInc="${SDKDIR}Include\um;${SDKDIR}Include\Shared;${SDKDIR}Include\WinRT"
$KitLib32="${SDKDIR}Lib\win8\um\x86"
$KitLib64="${SDKDIR}Lib\win8\um\x64"
$KitLibARM="${SDKDIR}LIB\win8\um\ARM"

IF($target -eq 1){
    $CompilerDir="${VCDir}bin"
    $Library="${VCDir}lib"
    $env:Path="$CompilerDir;$KitBin32;$IDE;$env:PATH"
    $env:INCLUDE="$KitInc;${VCDir}Include;$env:INCLUDE"
    $env:LIB="$KitLib32;${VCDir}LIB;$env:LIB"
}ELSEIF($target -eq 2){
    $CompilerDir="${VCDir}bin\x86_amd64"
    $Library="${VCDir}lib\x86_amd64"
    $env:Path="$CompilerDir;${VCDir}bin;$KitBin64;$IDE;$env:PATH"
    $env:INCLUDE="$KitInc;${VCDir}Include;$env:INCLUDE"
    $env:LIB="$KitLib64;${VCDir}Lib\amd64;$env:LIB"
}ELSEIF($target -eq 3){
    $CompilerDir="${VCDir}bin\x86_ARM"
    $Library="${VCDir}lib\arm"
    $env:Path="$CompilerDir;${VCDir}bin;$KitBinARM;$KitBin32;$IDE;$env:PATH"
    $env:INCLUDE="$KitInc;${VCDir}Include;$env:INCLUDE"
    $env:LIB="$KitLibARM;${VCDir}LIB\arm;$env:LIB"
}
