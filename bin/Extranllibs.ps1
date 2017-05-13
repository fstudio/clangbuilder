#!/usr/bin/env powershell

# Loading Extranl Libs

param(
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch = "x64"
)

$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot
$ExtranllibsDir = "$ClangbuilderRoot\libs"

if (Test-Path "$ExtranllibsDir\$Arch\include") {
    $env:INCLUDE = "$env:INCLUDE;$ExtranllibsDir\$Arch\include"
}
if (Test-Path "$ExtranllibsDir\$Arch\lib") {
    $env:LIB = "$env:LIB;$ExtranllibsDir\$Arch\lib"
}
if (Test-Path "$ExtranllibsDir\$Arch\bin") {
    $env:PATH = "$env:PATH;$ExtranllibsDir\$Arch\bin"
}

if (Test-Path "$Extranllibs\$Arch\libs") {
    $env:LIB = "$env:LIB;$Extranllibs\$Arch\libs"
}


