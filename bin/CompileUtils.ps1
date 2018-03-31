#!/usr/bin/env powershell
# Clangbuilder compile clangbuilderui ...
."$PSScriptRoot\ProfileEnv.ps1"
Import-Module -Name "$ClangbuilderRoot\modules\Initialize"
Import-Module -Name "$ClangbuilderRoot\modules\VisualStudio"
Import-Module -Name "$ClangbuilderRoot\modules\Devinstall" # Package Manager

$ret = DevinitializeEnv -Devlockfile "$ClangbuilderRoot/bin/pkgs/devlock.json"
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
Set-Location "$ClangbuilderRoot\tools\ClangbuilderUI"
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
    if (!(Test-Path "$ClangbuilderRoot\ClangbuilderUI.lnk")) {
        $cswshell = New-Object -ComObject WScript.Shell
        $clangbuilderlnk = $cswshell.CreateShortcut("$ClangbuilderRoot\ClangbuilderUI.lnk")
        $clangbuilderlnk.TargetPath = "$ClangbuilderRoot\bin\utils\ClangbuilderUI.exe"
        $clangbuilderlnk.Description = "Start ClangbuilderUI"
        $clangbuilderlnk.WindowStyle = 1
        $clangbuilderlnk.WorkingDirectory = "$ClangbuilderRoot\bin\utils"
        $clangbuilderlnk.IconLocation = "$ClangbuilderRoot\bin\utils\ClangbuilderUI.exe,0"
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
