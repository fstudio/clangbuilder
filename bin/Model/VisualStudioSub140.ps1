<#############################################################################
#  VisualStudioSub140.ps1
#  Note: Clang Auto Build Environment for Visual Studio 2015 [Windows 8.1]
#  Date:2016.01.01
#  Author:Force <forcemz@outlook.com>
##############################################################################>
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch="x64"
)
IF($PSVersionTable.PSVersion.Major -lt 3)
{
    $PSVersionString=$PSVersionTable.PSVersion.Major
    Write-Error "Clangbuilder must run under PowerShell 3.0 or later host environment !"
    Write-Error "Your PowerShell Version:$PSVersionString"
    if($Host.Name -eq "ConsoleHost"){
        [System.Console]::ReadKey()
    }
    Exit
}
IF( $env:VS140COMNTOOLS -eq $null -or (Test-Path $env:VS140COMNTOOLS) -eq $false)
{
  Write-Error "Not Fond Vaild Install for Visual Studio 2015"
  return
}

#IF($Arch -eq "x86"){
#    $target=1
#}
#IF($Arch -eq "x64"){
#    $target=2
#}
#IF($Arch -eq "ARM"){
#    $target=3
#}
IF($Arch -eq "ARM64"){
    Write-Error "Visual Studio 2015 [Windows 8] not support ARM64"
    Exit
}

$InvokerDir=$PSScriptRoot;
. "$InvokerDir/VisualStudioShared.ps1"

IF(${env:ProgramFiles(x86)} -eq $null){
   $SystemType=32
   $ProgramDir=${env:ProgramFiles}
}ELSE{
   $SystemType=64
   $ProgramDir=${env:ProgramFiles(x86)}
}

IF($SystemType -eq 64)
{
    $VSInstall=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VS7' '14.0'
    $VCDir=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7' '14.0'
    $SDKDIR=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v8.1' 'InstallationFolder'
    $NetTools=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v8.1A\WinSDK-NetFx40Tools-x64' 'InstallationFolder'
    $FrameworkDir=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7' 'FrameworkDir64'
    $FrameworkVer=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7' 'FrameworkVer64'
    IF((Test-Path  'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\12.0\Setup\F#')){
        $FSharpDir=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\14.0\Setup\F#' 'ProductDir'
    }
    $MSBUILDKIT=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSBuild\14.0' 'MSBuildOverrideTasksPath'
}ELSE{
    $VSInstall=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VS7' '14.0'
    $VCDir=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VC7' '14.0'
    $SDKDIR=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v8.1' 'InstallationFolder'
    $NetTools=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v8.1A\WinSDK-NetFx40Tools' 'InstallationFolder'
    $FrameworkDir=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VC7' 'FrameworkDir32'
    $FrameworkVer=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VC7' 'FrameworkVer32'
    IF((Test-Path  'HKLM:\SOFTWARE\Microsoft\VisualStudio\12.0\Setup\F#')){
        $FSharpDir=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\Setup\F#' 'ProductDir'
    }
    $MSBUILDKIT=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\MSBuild\14.0' 'MSBuildOverrideTasksPath'
}

IF($FSharpDir -eq $null)
{
    $env:Path="$NetTools;${FrameworkDir}${FrameworkVer};$env:Path"
}ELSE{
    $env:Path="$FSharpDir;$NetTools;${FrameworkDir}${FrameworkVer};$env:Path"
}

$IDE="${env:VS410COMNTOOLS}..\IDE"
$KitBin32="${SDKDIR}bin\x86"
$kitBin64="${SDKDIR}bin\amd64"
$KitBinARM="${SDKDIR}bin\ARM"
$KitInc="${SDKDIR}Include\um;${SDKDIR}Include\Shared;${SDKDIR}Include\WinRT"
$KitLib32="${SDKDIR}Lib\winv6.3\um\x86"
$KitLib64="${SDKDIR}Lib\winv6.3\um\x64"
$KitLibARM="${SDKDIR}Lib\winv6.3\um\arm"

IF($Arch -eq "x86"){
    $CompilerDir="${VCDir}bin"
    $Library="${VCDir}lib"
    $env:Path="$CompilerDir;${MSBUILDKIT};$KitBin32;$IDE;$env:PATH"
    $env:INCLUDE="$KitInc;${VCDir}Include;$env:INCLUDE"
    $env:LIB="$KitLib32;${VCDir}LIB;$env:LIB"
}ELSEIF($Arch -eq "x64"){
    $CompilerDir="${VCDir}bin\x86_amd64"
    $Library="${VCDir}lib\x86_amd64"
    $env:Path="$CompilerDir;${VCDir}bin;${MSBUILDKIT}\amd64;$KitBin64;$IDE;$env:PATH"
    $env:INCLUDE="$KitInc;${VCDir}Include;$env:INCLUDE"
    $env:LIB="$KitLib64;${VCDir}Lib\amd64;$env:LIB"
}ELSEIF($Arch -eq "ARM"){
    $CompilerDir="${VCDir}bin\x86_arm"
    $Library="${VCDir}lib\arm"
    $env:Path="$CompilerDir;${VCDir}bin;${MSBUILDKIT};$KitBinARM;$KitBin32;$IDE;$env:PATH"
    $env:INCLUDE="$KitInc;${VCDir}Include;$env:INCLUDE"
    $env:LIB="$KitLibARM;${VCDir}LIB\arm;$env:LIB"
}
