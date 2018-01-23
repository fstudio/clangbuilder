#!/usr/bin/env powershell
# Clangbuilder compile clangbuilderui ...
$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot

Import-Module -Name "$ClangbuilderRoot\modules\Initialize"
Import-Module -Name "$ClangbuilderRoot\modules\VisualStudio"

Push-Location $PWD
Set-Location $PSScriptRoot

DefaultVisualStudio -ClangbuilderRoot $ClangbuilderRoot # initialize default visual studio

Set-Location "$ClangbuilderRoot\tools\ClangbuilderUI"
Write-Host "Building ClangbuilderUI ..."
&nmake

if (!(Test-Path "ClangbuilderUI.exe")) {
    Write-Error "Build ClangbuilderUI.exe failed"
    Pop-Location
    return 1
}

if (!(Test-Path "$ClangbuilderRoot\utils")) {
    mkdir -Force "$ClangbuilderRoot\utils"
}

Copy-Item -Path "ClangbuilderUI.exe" -Destination "$ClangbuilderRoot\utils"
&nmake clean
Set-Location $PSScriptRoot


if (Test-Path "$ClangbuilderRoot\utils\ClangbuilderUI.exe") {
    if (!(Test-Path "$ClangbuilderRoot\ClangbuilderUI.lnk")) {
        $cswshell = New-Object -ComObject WScript.Shell
        $clangbuilderlnk = $cswshell.CreateShortcut("$ClangbuilderRoot\ClangbuilderUI.lnk")
        $clangbuilderlnk.TargetPath = "$ClangbuilderRoot\utils\ClangbuilderUI.exe"
        $clangbuilderlnk.Description = "Start ClangbuilderUI"
        $clangbuilderlnk.WindowStyle = 1
        $clangbuilderlnk.WorkingDirectory = "$ClangbuilderRoot\utils"
        $clangbuilderlnk.IconLocation = "$ClangbuilderRoot\utils\ClangbuilderUI.exe,0"
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
