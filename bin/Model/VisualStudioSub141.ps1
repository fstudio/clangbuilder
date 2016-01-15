<#############################################################################
#  VisualStudioSub141.ps1
#  Note: Clang Auto Build Environment for Visual Studio 2015 [Windows 10]
#  Date:2016.01.01
#  Author:Force <forcemz@outlook.com>
##############################################################################>
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch="x64"
)
IF($PSVersionTable.BuildVersion.Major -lt 10){
    Write-Output -ForegroundColor Red "Visual Studio 2015 [Windows 10] must run under Windows 10 or Later "
    Exit
}

IF( $env:VS140COMNTOOLS -eq $null -or (Test-Path $env:VS140COMNTOOLS) -eq $false)
{
    Write-Output -ForegroundColor Red "Not Fond Vaild Install for Visual Studio 2015"
    exit
}

IF($Arch -eq "x86"){
    $target=1
}
IF($Arch -eq "x64"){
    $target=2
}
IF($Arch -eq "ARM"){
    $target=3
}
IF($Arch -eq "ARM64"){
    $target=4
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
    $SDKDIR=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v10.0' 'InstallationFolder'
    $ProductVersion=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v10.0' 'ProductVersion'
    IF(Test-Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\NETFXSDK\4.6.1\WinSDK-NetFx40Tools-x64'){
        $NetTools=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\NETFXSDK\4.6.1\WinSDK-NetFx40Tools-x64' 'InstallationFolder'
    }ELSEIF(Test-Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\NETFXSDK\4.6\WinSDK-NetFx40Tools-x64'){
        $NetTools=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\NETFXSDK\4.6\WinSDK-NetFx40Tools-x64' 'InstallationFolder'
    }ELSEIF(Test-Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v8.1A\WinSDK-NetFx40Tools-x64'){
         $NetTools=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SDKs\Windows\v8.1A\WinSDK-NetFx40Tools-x64' 'InstallationFolder'
    }
    $FrameworkDir=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7' 'FrameworkDir64'
    $FrameworkVer=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VC7' 'FrameworkVer64'
    IF((Test-Path  'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\14.0\Setup\F#')){
    $FSharpDir=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\14.0\Setup\F#' 'ProductDir'
    }
    $MSBUILDKIT=Get-RegistryValue 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSBuild\14.0' 'MSBuildOverrideTasksPath'

}ELSE{
    $VSInstall=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VS7' '14.0'
    $VCDir=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VC7' '14.0'
    $SDKDIR=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v10.0' 'InstallationFolder'
    $ProductVersion=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v10.0' 'ProductVersion'
    IF(Test-Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\NETFXSDK\4.6.1\WinSDK-NetFx40Tools'){
        $NetTools=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\NETFXSDK\4.6.1\WinSDK-NetFx40Tools' 'InstallationFolder'
    }ELSEIF(Test-Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\NETFXSDK\4.6\WinSDK-NetFx40Tools'){
        $NetTools=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\NETFXSDK\4.6\WinSDK-NetFx40Tools' 'InstallationFolder'
    }ELSEIF(Test-Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v8.1A\WinSDK-NetFx40Tools'){
         $NetTools=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\Microsoft SDKs\Windows\v8.1A\WinSDK-NetFx40Tools' 'InstallationFolder'
    }
    $FrameworkDir=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VC7' 'FrameworkDir32'
    $FrameworkVer=Get-RegistryValue 'HKLM:\SOFTWARE\Microsoft\VisualStudio\SxS\VC7' 'FrameworkVer32'
    IF((Test-Path  'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\Setup\F#')){
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

$IDE="${env:VS110COMNTOOLS}..\IDE"
$KitBin32="${SDKDIR}bin\x86"
$kitBin64="${SDKDIR}bin\amd64"
$KitBinARM="${SDKDIR}bin\ARM"
$KitBinARM64="${SDKDIR}bin\ARM64"
$KitInc="${SDKDIR}Include\${ProductVersion}\ucrt;${SDKDIR}Include\${ProductVersion}\um;${SDKDIR}Include\${ProductVersion}\Shared;${SDKDIR}Include\${ProductVersion}\WinRT"
$KitLib32="${SDKDIR}Lib\${ProductVersion}\um\x86;${SDKDIR}Lib\${ProductVersion}\ucrt\x86"
$KitLib64="${SDKDIR}Lib\${ProductVersion}\um\x64;${SDKDIR}Lib\${ProductVersion}\ucrt\x64"
$KitLibARM="${SDKDIR}LIB\${ProductVersion}\um\ARM;${SDKDIR}Lib\${ProductVersion}\ucrt\ARM"
$KitLibARM64="${SDKDIR}LIB\${ProductVersion}\um\ARM64;${SDKDIR}Lib\${ProductVersion}\ucrt\ARM64"

IF($target -eq 1){
    $CompilerDir="${VCDir}bin"
    $Library="${VCDir}lib"
    $env:Path="$CompilerDir;${MSBUILDKIT};$KitBin32;$IDE;$env:PATH"
    $env:INCLUDE="$KitInc;${VCDir}Include;$env:INCLUDE"
    $env:LIB="$KitLib32;${VCDir}LIB;$env:LIB"
}ELSEIF($target -eq 2){
    $CompilerDir="${VCDir}bin\x86_amd64"
    $Library="${VCDir}lib\x86_amd64"
    $env:Path="$CompilerDir;${VCDir}bin;${MSBUILDKIT}\amd64;$KitBin64;$IDE;$env:PATH"
    $env:INCLUDE="$KitInc;${VCDir}Include;$env:INCLUDE"
    $env:LIB="$KitLib64;${VCDir}Lib\amd64;$env:LIB"
}ELSEIF($target -eq 3){
    $CompilerDir="${VCDir}bin\x86_ARM"
    $Library="${VCDir}lib\arm"
    $env:Path="$CompilerDir;${VCDir}bin;${MSBUILDKIT};$KitBinARM;$KitBin32;$IDE;$env:PATH"
    $env:INCLUDE="$KitInc;${VCDir}Include;$env:INCLUDE"
    $env:LIB="$KitLibARM;${VCDir}LIB\arm;$env:LIB"
}ELSEIF($target -eq 4){
    $CompilerDir="${VCDir}bin\x86_ARM64"
    $Library="${VCDir}lib\arm64"
    $env:Path="$CompilerDir;${VCDir}bin;${MSBUILDKIT};$KitBinARM;$KitBin32;$IDE;$env:PATH"
    $env:INCLUDE="$KitInc;${VCDir}Include;$env:INCLUDE"
    $env:LIB="$KitLibARM;${VCDir}LIB\arm64;$env:LIB"
}
