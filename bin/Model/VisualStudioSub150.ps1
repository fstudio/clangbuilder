<#############################################################################
#  VisualStudioSub150.ps1
#  Note: Clang Auto Build Environment for Visual Studio 15 Preview [Windows 10]
#  Date:2016.04.01
#  Author:Force <forcemz@outlook.com>
##############################################################################>
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch="x64"
)
IF($PSVersionTable.BuildVersion.Major -lt 10){
    Write-Error "Visual Studio 15 [Preview] must run under Windows 10 or Later "
    Exit
}


. "$PSScriptRoot/VisualStudioShared.ps1"


$RegRouter="HKLM:\SOFTWARE\Microsoft"
#vcpackages
#$NativeAMD64=$False

$IsWindows64=[System.Environment]::Is64BitOperatingSystem

IF($IsWindows64)
{
    $RegRouter="HKLM:\SOFTWARE\Wow6432Node\Microsoft"
}


$VSInstallRoot=Get-RegistryValueEx -Path "$RegRouter\VisualStudio\SxS\VS7" -Key '15.0'
$VisualCppEnvFile="${VSInstallRoot}Common7\IDE\VisualCpp\Auxiliary\Build\vcvarsall.bat"

$BuiltinCMake="${VSInstallRoot}Common7\IDE\CommonExtensions\Microsoft\CMake\CMake"

if((Test-Path $BuiltinCMake)){
    Push-PathFront -Path "$BuiltinCMake\bin"
}

if($Arch -eq "ARM"){
    Invoke-BatchFile -Path $VisualCppEnvFile -ArgumentList x86_arm
}elseif($Arch -eq "ARM64"){
    Write-Host "ARM64 stay tuned !"
}else{
    Invoke-BatchFile -Path $VisualCppEnvFile -ArgumentList $Arch
}