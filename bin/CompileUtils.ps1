#!/usr/bin/env pwsh
# Clangbuilder compile clangbuilderui ...
."$PSScriptRoot\PreInitialize.ps1"
Import-Module -Name "$ClangbuilderRoot\modules\Initialize"
Import-Module -Name "$ClangbuilderRoot\modules\VisualStudio"
Import-Module -Name "$ClangbuilderRoot\modules\Devi" # Package Manager
Import-Module -Name "$ClangbuilderRoot\modules\Utils" # Package Manager

$ret = DevinitializeEnv -ClangbuilderRoot $ClangbuilderRoot
if ($ret -ne 0) {
    # Need vswhere
    exit 1
}
Push-Location $PWD

$ret = DefaultVisualStudio -ClangbuilderRoot $ClangbuilderRoot # initialize default visual studio
if ($ret -ne 0) {
    Write-Host -ForegroundColor Red "Not found valid installed visual studio."
    exit 1
}
if (Test-Path "$ClangbuilderRoot/bin/pkgs/cmake/bin/cmake.exe") {
    $cmakeexe = "$ClangbuilderRoot/bin/pkgs/cmake/bin/cmake.exe"
}

if ($null -eq $cmakeexe) {
    $cmakeexes = Get-Command -Name "cmake.exe" -CommandType Application -ErrorAction SilentlyContinue
    if ($null -eq $cmakeexes) {
        Write-Host -ForegroundColor Red "You should be in VisualStudio select install cmake"
        exit 1
    }
    $cmakeexe = $cmakeexes[0].Source
}



## Add environment
InitializeEnv -ClangbuilderRoot $ClangbuilderRoot
New-Item -ItemType Directory -Force -ErrorAction SilentlyContinue "$ClangbuilderRoot\bin\utils" | Out-Null
$OutDir = "$ClangbuilderRoot\sources\out"
New-Item -ItemType Directory -Force $OutDir -ErrorAction SilentlyContinue | Out-Null
Remove-Item -Force "$OutDir\*" -Recurse -ErrorAction SilentlyContinue # remove build 
Write-Host "Building Clangbuilder Utils ..."
$ec = ProcessExec -FilePath $cmakeexe -Argv "-G`"NMake Makefiles`" -DCMAKE_BUILD_TYPE=Release .." -WD $OutDir
if ($ec -ne 0) {
    exit $ec
}

$ec = ProcessExec -FilePath $cmakeexe -Argv "--build .  --config Release" -WD $OutDir
if ($ec -ne 0) {
    exit $ec
}

$Utils = "ClangbuilderUI.exe", "blast.exe", "cli.exe", "cmdex.exe"

foreach ($e in $Utils) {
    if (!(Test-Path "$OutDir\bin\$e")) {
        Write-Host -ForegroundColor Red "File: $OutDir\bin\$e not exists"
        exit 1
    }
    Copy-Item -Path "$OutDir\bin\$e" -Destination "$ClangbuilderRoot\bin\utils"
}

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

$LauncherUtils = "$ClangbuilderRoot\bin\utils\cli.exe"
$Blastexe = "$ClangbuilderRoot\bin\utils\blast.exe"
&$Blastexe --link $Blastexe "$ClangbuilderRoot\bin\blast.exe" -F # install self
&$Blastexe --link $LauncherUtils "$ClangbuilderRoot\bin\ClangbuilderTarget.exe" -F
&$Blastexe --link $LauncherUtils "$ClangbuilderRoot\bin\mklauncher.exe" -F
&$Blastexe --link $LauncherUtils "$ClangbuilderRoot\bin\devi.exe" -F

Remove-Item $OutDir -Force -Recurse -ErrorAction SilentlyContinue