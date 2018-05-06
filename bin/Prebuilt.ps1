#!/usr/bin/env pwsh
$ClangbuilderRoot = Split-Path $PSScriptRoot
Import-Module -Name "$ClangbuilderRoot\modules\Devi" # Package Manager
$ret = DevinitializeEnv -ClangbuilderRoot $ClangbuilderRoot -Pkglocksdir "$ClangbuilderRoot\bin\pkgs\.locks"
if ($ret -ne 0) {
    exit 1
}


$szcmd = Get-Command "7z.exe" -ErrorAction SilentlyContinue
if ($szcmd -eq $null) {
    Write-Host "7z not install, 'please use devi install 7z'"
    exit 1
}


$revobj = Get-Content "$ClangbuilderRoot\config\revision.json" -ErrorAction SilentlyContinue|ConvertFrom-Json -ErrorAction SilentlyContinue

if ($revobj -eq $null -or $revobj.Release -eq $null) {
    Write-Host -ForegroundColor Red "Revision no set"
    exit 1
}
$relrev = $revobj.Release

$pbobj = Get-Content "$ClangbuilderRoot\config\prebuilt.json" -ErrorAction SilentlyContinue|ConvertFrom-Json -ErrorAction SilentlyContinue

if ($pbobj -ne $null -and ($pbobj.LLVM.Revision -ne $null)) {
    if ($pbobj.LLVM.Revision -eq $relrev) {
        Write-Host -ForegroundColor Yellow "llvm prebuilt binary $relrev already install. $($pbobj.LLVM.Path)"
        exit 0
    }
}

$Arch = "32"
if ([System.Environment]::Is64BitOperatingSystem) {
    $Arch = "64"
}

$dluri = "https://releases.llvm.org/$relrev/LLVM-$relrev-win$Arch.exe"

if (!(Test-Path "$ClangbuilderRoot\bin\utils")) {
    try {
        New-Item -ItemType Directory -Force "$ClangbuilderRoot\bin\utils"
    }
    catch {
        Write-Host -ForegroundColor Red "$_"
        exit 1
    }
}

$cmd = Get-Command "wget.exe" -ErrorAction SilentlyContinue
$dlname = "LLVM-$relrev-win$Arch.exe"
$outfile = "$ClangbuilderRoot\bin\utils\$dlname"
$wkdir = "$ClangbuilderRoot\bin\utils"

$WindowTitleBase = $Host.UI.RawUI.WindowTitle

Write-Host "download $dluri"

if ($cmd -ne $null) {
    $process = Start-Process -FilePath "wget.exe" -ArgumentList "$dluri -O $dlname" -WorkingDirectory $wkdir -PassThru -Wait -NoNewWindow
    if ($process.ExitCode -ne 0) {
        if (Test-Path $outfile) {
            Remove-Item -Force $outfile
        }
        Write-Host "wget download file error: $($process.ExitCode)"
        exit 1
    }
}
else {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $XUA = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
    try {
        Invoke-WebRequest -Uri $dluri -OutFile $outfile -UserAgent $XUA -UseBasicParsing
    }
    catch {
        Write-Host "pwsh download file error: $_"
        exit 1
    }
}

$Host.UI.RawUI.WindowTitle = $WindowTitleBase

$tempdir = "$wkdir\clang.$PID"
if (Test-Path "$wkdir\clang") {
    Move-Item -Force "$wkdir\clang" $tempdir -ErrorAction SilentlyContinue
}


$p7 = Start-Process -FilePath "7z.exe" -ArgumentList "e -spf -y $dlname -oclang"  -WorkingDirectory $wkdir  -PassThru -Wait -NoNewWindow

if ($p7.ExitCode -ne 0) {
    Write-Host "7z decompress $dlname failed"
    Remove-Item -Force "$outfile"
    if (Test-Path  "$wkdir\clang") {
        Remove-Item -Force -Recurse "$wkdir\clang"
    }
    if (Test-Path $tempdir) {
        Move-Item -Force  $tempdir "$wkdir\clang" -ErrorAction SilentlyContinue |Out-Null
    }
    exit 1
}

if (Test-Path $tempdir) {
    Remove-Item -Force -Recurse $tempdir
}

Remove-Item "$wkdir\clang\`$PLUGINSDIR" -Recurse -Force -ErrorAction SilentlyContinue |Out-Null
Remove-Item "$wkdir\clang\Uninstall.exe" -Force  -ErrorAction SilentlyContinue |Out-Null
Remove-Item -Force  $outfile -ErrorAction SilentlyContinue |Out-Null

$jsonbase = @{}
$llvmbase = @{}
$llvmbase["Path"] = "$wkdir\clang"
$llvmbase["Arch"] = "x$Arch"
$llvmbase["Revision"] = $relrev
$jsonbase["LLVM"] = $llvmbase

ConvertTo-Json $jsonbase|Out-File -Force -FilePath "$ClangbuilderRoot\config\prebuilt.json"
