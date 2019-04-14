#!/usr/bin/env pwsh
# Clangbuilder compile clangbuilderui ...
."$PSScriptRoot\PreInitialize.ps1"
Import-Module -Name "$ClangbuilderRoot\modules\Initialize"
Import-Module -Name "$ClangbuilderRoot\modules\VisualStudio"
Import-Module -Name "$ClangbuilderRoot\modules\Devi" # Package Manager

$ret = DevinitializeEnv -ClangbuilderRoot $ClangbuilderRoot -Pkglocksdir $Pkglocksdir
if ($ret -ne 0) {
    # Need vswhere
    exit 1
}
Push-Location $PWD
Set-Location $PSScriptRoot

$ret = DefaultVisualStudio -ClangbuilderRoot $ClangbuilderRoot # initialize default visual studio
if ($ret -ne 0) {
    Write-Host -ForegroundColor Red "Not found valid installed visual studio."
    exit 1
}
## Add environment
InitializeEnv -ClangbuilderRoot $ClangbuilderRoot
Set-Location "$ClangbuilderRoot\sources\cbui"
Write-Host "Building ClangbuilderUI ..."
&nmake

if (!(Test-Path "ClangbuilderUI.exe")) {
    Write-Error "Build ClangbuilderUI.exe failed"
    Pop-Location
    return 1
}

if (!(Test-Path "$ClangbuilderRoot\bin\utils")) {
    mkdir -Force "$ClangbuilderRoot\bin\utils"
}

Copy-Item -Path "ClangbuilderUI.exe" -Destination "$ClangbuilderRoot\bin\utils"
&nmake clean
Set-Location $PSScriptRoot


if (Test-Path "$ClangbuilderRoot\bin\utils\ClangbuilderUI.exe") {
    $cswshell = New-Object -ComObject WScript.Shell
    $clangbuilderlnk = $cswshell.CreateShortcut("$ClangbuilderRoot\ClangbuilderUI.lnk")
    $clangbuilderlnk.TargetPath = "$ClangbuilderRoot\bin\utils\ClangbuilderUI.exe"
    $clangbuilderlnk.Description = "Start ClangbuilderUI"
    $clangbuilderlnk.WindowStyle = 1
    $clangbuilderlnk.WorkingDirectory = "$ClangbuilderRoot\bin\utils"
    $clangbuilderlnk.IconLocation = "$ClangbuilderRoot\bin\utils\ClangbuilderUI.exe,0"
    # support overwrite
    $clangbuilderlnk.Save()
}
else {
    Write-Error "Cannot found ClangbuilderUI.exe "
}
Set-Location "$ClangbuilderRoot\sources\blast"
&nmake
if (Test-Path "$ClangbuilderRoot\sources\blast\blast.exe") {
    Copy-Item -Path  "$ClangbuilderRoot\sources\blast\blast.exe" -Destination  "$ClangbuilderRoot\bin"
}
&nmake clean

Pop-Location

Set-Location "$ClangbuilderRoot\sources\cli"
&nmake
if (Test-Path "$ClangbuilderRoot\sources\cli\cli.exe") {
    Copy-Item -Path  "$ClangbuilderRoot\sources\cli\cli.exe" -Destination  "$ClangbuilderRoot\bin\utils"
}
&nmake clean

Pop-Location

$LauncherUtils = "$ClangbuilderRoot\bin\utils\cli.exe"
$Blastexe = "$ClangbuilderRoot\bin\blast.exe"


if (!(Test-Path "$ClangbuilderRoot\bin\ClangbuilderTarget.exe")) {
    &$Blastexe --link $LauncherUtils "$ClangbuilderRoot\bin\ClangbuilderTarget.exe"
}

if (!(Test-Path "$ClangbuilderRoot\bin\mklauncher.exe")) {
    &$Blastexe --link $LauncherUtils "$ClangbuilderRoot\bin\mklauncher.exe"
}

if (!(Test-Path "$ClangbuilderRoot\bin\devi.exe")) {
    &$Blastexe --link $LauncherUtils "$ClangbuilderRoot\bin\devi.exe"
}