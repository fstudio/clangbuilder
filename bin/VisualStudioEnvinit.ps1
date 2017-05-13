#!/usr/bin/env poewershell
# Initialize Visual Studio Environment
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch = "x64",
    [ValidateSet("11.0", "12.0", "14.0", "15.0")]
    [String]$VisualStudio = "14.0",
    [Switch]$Sdklow = $false
)

Function Get-RegistryValue($key, $value) { 
    (Get-ItemProperty $key $value).$value 
}

Function Get-RegistryValueEx {
    param(
        [ValidateNotNullorEmpty()]
        [String]$Path,
        [ValidateNotNullorEmpty()]
        [String]$Key
    )
    if (!(Test-Path $Path)) {
        return 
    }
    (Get-ItemProperty $Path $Key).$Key
}


Function Invoke-Vcvarsall {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [string] $ArgumentList
    )
    Set-StrictMode -Version Latest
    $tempFile = [IO.Path]::GetTempFileName()
    cmd /c " `"$Path`" $argumentList && set > `"$tempFile`" "
    ## Go through the environment variables in the temp file.
    ## For each of them, set the variable in our local environment.
    Get-Content $tempFile | Foreach-Object {
        if ($_ -match "^(.*?)=(.*)$") {
            Set-Content "env:\$($matches[1])" $matches[2]
        }
    }
    Remove-Item $tempFile
}


$RegRouter = "HKLM:\SOFTWARE\Microsoft"
$IsWindows64 = [System.Environment]::Is64BitOperatingSystem

IF ($IsWindows64) {
    $RegRouter = "HKLM:\SOFTWARE\Wow6432Node\Microsoft"
}

$ArchListX86 = @{
    "x86"   = "x86";
    "x64"   = "x86_amd64";
    "ARM"   = "x86_arm";
    "ARM64" = "x64_arm64"
}

$ArchListX64 = @{
    "x86"   = "amd64_x86";
    "x64"   = "amd64";
    "ARM"   = "amd64_arm";
    "ARM64" = "amd64_arm64"
}

if ($IsWindows64) {
    $ArgumentList = $ArchListX64[$Arch]
}
else {
    $ArgumentList = $ArchListX86[$Arch]
}


$VSInstallRoot = Get-RegistryValueEx -Path "$RegRouter\VisualStudio\SxS\VS7" -Key $VisualStudio

if ($null -eq $VSInstallRoot) {
    Write-Error "Visual Studio $VS Not install in your system !"
    return 1;
}


if ($VisualStudio -eq "15.0") {
    $vsinstalls = vswhere -format json|ConvertFrom-JSON
    foreach ($vs in $vsinstalls) {
        if ($vs.channelId -eq "VisualStudio.15.Release") {
            $vs15install = $vs.installationPath
            $vs15version = $vs.installationVersion
            Write-Host "Use: $vs15install $vs15version"
            $VisualCppEnvFile = "$vs15install\VC\Auxiliary\Build\vcvarsall.bat"
        }
    }
}
else {
    $VisualCppEnvFile = "${VSInstallRoot}\VC\vcvarsall.bat"
}

if ($Sdklow) {
    Write-Host "Attention Please: Use Windows 8.1 SDK"
    $ArgumentList += " 8.1"
}

Invoke-Vcvarsall -Path $VisualCppEnvFile -ArgumentList $ArgumentList
