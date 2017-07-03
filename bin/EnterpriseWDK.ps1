#!/usr/bin/env powershell
# EnterpriseWDK support ARM64 Target
# Program Files\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt

$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot
$EWDKFile = "$ClangbuilderRoot\config\ewdk.json"

if (!(Test-Path $EWDKFile)) {
    Write-Error "Not Enterprise WDK config file"
    return 1
}

$EWDKObj = Get-Content -Path "$EWDKFile" |ConvertFrom-Json

$EWDKPath = $EWDKObj.Path
$EWDKVersion = $EWDKObj.Version

if (!(Test-Path $EWDKPath)) {
    Write-Error "Not Enterprise WDK directory !"
    return 1
}

Write-Host "Initialize Windows 10 Enterprise WDK ARM Environment ..."

Write-Host "Enterprise WDK Version: $EWDKVersion"

$BuildTools = "$EWDKPath\Program Files\Microsoft Visual Studio\2017\BuildTools"
$SDKKIT = "$EWDKPath\Program Files\Windows Kits\10"
$VCToolsVersion = (Get-Content "$BuildTools\VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt").Trim()

Write-Host "Visual C++ Version: $VCToolsVersion"

# Configuration Include Path
$env:INCLUDE = "$BuildTools\VC\Tools\MSVC\$VCToolsVersion\include;$BuildTools\VC\Tools\MSVC\$VCToolsVersion\atlmfc\include;"
$includedirs = Get-ChildItem -Path "$SDKKIT\include\$EWDKVersion" | Foreach-Object {$_.FullName}
foreach ($_i in $includedirs) {
    $env:INCLUDE = "$env:INCLUDE;$_i"
}

$IsWindows64 = [System.Environment]::Is64BitOperatingSystem

if ($IsWindows64) {
    $HostEnv = "x64"
}
else {
    $HostEnv = "x86"
}

$env:PATH += "$SDKKIT\bin\$EWDKVersion\$HostEnv;$BuildTools\VC\Tools\MSVC\$VCToolsVersion\bin\Host$HostEnv\arm64\;"
$env:PATH += "$BuildTools\VC\Tools\MSVC\$VCToolsVersion\onecore\$HostEnv\Microsoft.VC150.CRT\;$SDKKIT\Redist\ucrt\DLLs\$HostEnv"
$env:PATH += "$EWDKFile\Program Files\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.7.1 Tools;$BuildTools\MSBuild\15.0\Bin"

$env:LIB = "$BuildTools\VC\Tools\MSVC\$VCToolsVersion\lib\arm64;$BuildTools\VC\Tools\MSVC\$VCToolsVersion\atlmfc\lib\arm64;"
$env:LIB += "$SDKKIT\lib\$EWDKVersion\km\arm64;$SDKKIT\lib\$EWDKVersion\um\arm64;$SDKKIT\lib\$EWDKVersion\ucrt\arm64;"

$env:LIBPATH="$BuildTools\VC\Tools\MSVC\$VCToolsVersion\lib\arm64;$BuildTools\VC\Tools\MSVC\$VCToolsVersion\atlmfc\lib\arm64;"
$env:LIBPATH="$SDKKIT\UnionMetadata\$EWDKVersion\;$SDKKIT\References\$EWDKVersion\;"