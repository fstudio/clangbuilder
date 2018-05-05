#!/usr/bin/env pwsh

$szcmd = Get-Command "7z.exe" -ErrorAction SilentlyContinue
if ($szcmd -eq $null) {
    Write-Host "7z not install, 'please use devi install 7z'"
    exit 1
}

$ClangbuilderRoot = Split-Path $PSScriptRoot
$revobj = Get-Content "$ClangbuilderRoot\config\revision.json" -ErrorAction SilentlyContinue|ConvertFrom-Json -ErrorAction SilentlyContinue

if ($revobj -eq $null -or $revobj.Release -eq $null) {
    Write-Host -ForegroundColor Red "Revision no set"
    exit 1
}
$relrev = $revobj.Release


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
$filename = "LLVM-$relrev-win$Arch.exe"
$outfile = "$ClangbuilderRoot\bin\utils\$filename"
$wkdir = "$ClangbuilderRoot\bin\utils"

if ($cmd -ne $null) {
    $process = Start-Process -FilePath "wget.exe" -ArgumentList "$dluri -O $outfile" -WorkingDirectory $wkdir -PassThru -Wait -NoNewWindow
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




$p7 = Start-Process -FilePath "7z.exe" -ArgumentList "7z e -spf -y $filename -oclang"  -WorkingDirectory $wkdir  -PassThru -Wait -NoNewWindow

if ($p7.ExitCode -ne 0) {
    Write-Host "7z decompress $filename failed"
    Remove-Item -Force "$outfile"
    exit 1
}

Remove-Item "$wkdir\clang\`$PLUGINSDIR" -Recurse -Force
Remove-Item "$wkdir\clang\Unintsall.exe" -Force

$jsonbase = @{}
$llvmbase = @{}
$llvmbase["Path"] = "$wkdir\clang"
$llvmbase["Arch"] = "x$Arch"
$jsonbase["LLVM"] = $llvmbase

ConvertTo-Json $jsonbase|Out-File -Force -FilePath "$ClangbuilderRoot\config\prebuilt.json"
