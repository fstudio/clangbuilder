#!/usr/bin/env pwsh
# Initialize or update llvm clang sources for git
param(
    [Switch]$LLDB,
    [ValidateSet("Mainline", "Stable")]
    [String]$Branch = "Mainline"
)

."$PSScriptRoot\PreInitialize.ps1"

Function Update-LLVM {
    param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Checkout URL")]
        [ValidateNotNullorEmpty()]
        [String]$URL,
        [Parameter(Position = 1, Mandatory = $True, HelpMessage = "Enter Checkout Folder")]
        [ValidateNotNullorEmpty()]
        [String]$Folder,
        [Parameter(Position = 2, Mandatory = $True, HelpMessage = "Enter checkout branch")]
        [ValidateNotNullorEmpty()]
        [String]$Branch
    )
    Push-Location $PWD
    IF ((Test-Path "$Folder") -and (Test-Path "$Folder/.git")) {
        Set-Location "$Folder"
        Write-Host "Update $Folder"
        &git checkout .
        &git pull origin $Branch
    }
    ELSE {
        IF ((Test-Path "$Folder")) {
            Remove-Item -Force -Recurse "$Folder"
        }
        Write-Host "clone $URL"
        &git clone $URL --depth=1 --single-branch --branch $Branch "$Folder"
    }
    Pop-Location
}

$LLVMRepositoriesRoot = "https://github.com/llvm-mirror"
$OutDir = "$ClangbuilderRoot\out"

$RevisionObj = Get-Content -Path "$ClangbuilderRoot/config/revision.json" |ConvertFrom-Json


switch ($Branch) {
    {$_ -eq "Mainline"} {
        $BranchName = "master"
        $SourcesDir = "$OutDir\mainline"
    } {$_ -eq "Stable"} {
        $BranchName = $RevisionObj.Stable
        $SourcesDir = "$OutDir\$BranchName"
    }
}

Update-LLVM -URL "$LLVMRepositoriesRoot/llvm.git" -Folder $SourcesDir -Branch $BranchName
if (!(Test-Path "$SourcesDir\tools")) {
    Write-Output "clone llvm sources failed"
    Exit
}

Set-Location "$SourcesDir\tools"
Update-LLVM -URL "$LLVMRepositoriesRoot/clang.git" -Folder "clang" -Branch $BranchName
Update-LLVM -URL "$LLVMRepositoriesRoot/lld.git" -Folder "lld" -Branch $BranchName

IF ($LLDB) {
    Update-LLVM -URL "$LLVMRepositoriesRoot/lldb.git" -Folder "lldb" -Branch $BranchName
}
else {
    if (Test-Path "$SourcesDir\tools\lldb") {
        Remove-Item -Force -Recurse "$SourcesDir\tools\lldb"
    }
}

if (!(Test-Path "$SourcesDir/tools/clang/tools")) {
    Write-Output "clone clang source failed"
    Exit
}

Set-Location "$SourcesDir/tools/clang/tools"
Update-LLVM -URL "$LLVMRepositoriesRoot/clang-tools-extra.git" -Folder "extra" -Branch $BranchName
Set-Location "$SourcesDir/projects"
Update-LLVM -URL "$LLVMRepositoriesRoot/compiler-rt.git" -Folder "compiler-rt" -Branch $BranchName
Update-LLVM -URL "$LLVMRepositoriesRoot/libcxx.git" -Folder "libcxx" -Branch $BranchName
# current build libcxxabi failed when bootstrap
# Update-LLVM -URL "$LLVMRepositoriesRoot/libcxxabi.git" -Folder "libcxxabi" -Branch $BranchName
