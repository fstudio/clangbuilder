#!/usr/bin/env powershell
# Clangbuilder compile clangbuilderui ...
$ClangbuilderDir = Split-Path -Parent $PSScriptRoot


Push-Location $PWD
Set-Location $PSScriptRoot

$IsWindows64 = [System.Environment]::Is64BitOperatingSystem

if ($IsWindows64) {
    $Arch = "x64"
}
else {
    $Arch = "x86"
}

$env:PATH = "$ClangbuilderDir/pkgs/vswhere;$env:PATH"

$vsinstalls=$null
try {
    $vsinstalls = vswhere -prerelease -legacy -format json|ConvertFrom-JSON
}
catch {
    Write-Error "$_"
    Pop-Location
    exit 1
}

$InstanceId=$vsinstalls[0].instanceId

Invoke-Expression "$PSScriptRoot\VisualStudioEnvinitEx.ps1 -Arch $Arch -InstanceId $InstanceId"

Set-Location "$ClangbuilderDir\tools\ClangbuilderUI"
Write-Host "Building ClangbuilderUI ..."
&nmake

if (!(Test-Path "ClangbuilderUI.exe")) {
    Write-Error "Build ClangbuilderUI.exe failed"
    Pop-Location
    return 1
}

if (!(Test-Path "$ClangbuilderDir\utils")) {
    mkdir -Force "$ClangbuilderDir\utils"
}

Copy-Item -Path "ClangbuilderUI.exe" -Destination "$ClangbuilderDir\utils"
&nmake clean
Set-Location $PSScriptRoot


if (Test-Path "$ClangbuilderDir\utils\ClangbuilderUI.exe") {
    if (!(Test-Path "$ClangbuilderDir\ClangbuilderUI.lnk")) {
        $cswshell = New-Object -ComObject WScript.Shell
        $clangbuilderlnk = $cswshell.CreateShortcut("$ClangbuilderDir\ClangbuilderUI.lnk")
        $clangbuilderlnk.TargetPath = "$ClangbuilderDir\utils\ClangbuilderUI.exe"
        $clangbuilderlnk.Description = "Start ClangbuilderUI"
        $clangbuilderlnk.WindowStyle = 1
        $clangbuilderlnk.WorkingDirectory = "$ClangbuilderDir\utils"
        $clangbuilderlnk.IconLocation = "$ClangbuilderDir\utils\ClangbuilderUI.exe,0"
        $clangbuilderlnk.Save()
    }
    else {
        Write-Output "ClangbuilderUI.lnk already exists"
    }
}
else {
    Write-Error "Cannot found ClangbuilderUI.exe "
}


Pop-Location
