#!/usr/bin/env powershell
# Initialize or update llvm clang sources
param(
    [Switch]$LLDB,
    [Switch]$Mainline
)

Function Update-LLVM {
    param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Checkout URL")]
        [ValidateNotNullorEmpty()]
        [String]$URL,
        [Parameter(Position = 1, Mandatory = $True, HelpMessage = "Enter Checkout Folder")]
        [ValidateNotNullorEmpty()]
        [String]$Folder
    )
    Push-Location $PWD
    IF ((Test-Path "$Folder") -and (Test-Path "$Folder/.git")) {
        Set-Location "$Folder"
        Write-Host "Update $Folder"
        &git checkout .
        &git pull .
    }
    ELSE {
        IF ((Test-Path "$Folder")) {
            Remove-Item -Force -Recurse "$Folder"
        }
        Write-Host "clone $URL"
        &git clone $URL "$Folder" --depth=1
    }
    Pop-Location
}


$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot
#$LatestObj = Get-Content -Path "$ClangbuilderRoot/config/latest.json" |ConvertFrom-Json


$LLVMRepositoriesRoot = "https://github.com/llvm-mirror"
$OutDir = "$ClangbuilderRoot\out"


if ($Mainline) {
    $SourcesDir = "$OutDir\mainline"
}
else {
    $SourcesDir = "$OutDir\release"
}


Update-LLVM -URL "$LLVMRepositoriesRoot/llvm.git" -Folder $SourcesDir
if (!(Test-Path "$SourcesDir\tools")) {
    Write-Output "Clone LLVM failed"
    Exit
}

Set-Location "$SourcesDir\tools"
Update-LLVM -URL "$LLVMRepositoriesRoot/clang.git" -Folder "clang"
Update-LLVM -URL "$LLVMRepositoriesRoot/lld.git" -Folder "lld"

IF ($LLDB) {
    Update-LLVM -URL "$LLVMRepositoriesRoot/lldb.git" -Folder "lldb"
}
else {
    if (Test-Path "$SourcesDir\tools\lldb") {
        Remove-Item -Force -Recurse "$SourcesDir\tools\lldb"
    }
}

if (!(Test-Path "$SourcesDir/tools/clang/tools")) {
    Write-Output "Clone Clang Failed"
    Exit
}

Set-Location "$SourcesDir/tools/clang/tools"
Update-LLVM -URL "$LLVMRepositoriesRoot/clang-tools-extra.git" -Folder "extra"
Set-Location "$SourcesDir/projects"
Update-LLVM -URL "$LLVMRepositoriesRoot/compiler-rt.git" -Folder "compiler-rt"
Update-LLVM -URL "$LLVMRepositoriesRoot/libcxx.git" -Folder "libcxx"
Update-LLVM -URL "$LLVMRepositoriesRoot/libcxxabi.git" -Folder "libcxxabi"
