#!/usr/bin/env powershell
# Initialize or update llvm clang sources from subversion
param(
    [Switch]$LLDB,
    [ValidateSet("Mainline", "Stable", "Release")]
    [String]$Branch = "Mainline"
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
    IF ((Test-Path "$Folder") -and (Test-Path "$Folder/.svn")) {
        Set-Location "$Folder"
        Write-Host "Update $Folder"
        &svn cleanup .
        &svn up .
    }
    ELSE {
        IF ((Test-Path "$Folder")) {
            Remove-Item -Force -Recurse "$Folder"
        }
        Write-Host "Checkout $Folder"
        &svn co $URL "$Folder"
    }
    Pop-Location
}

Function CheckWorktree {
    param(
        [String]$Folder,
        [String]$Url
    )
    Push-Location $PWD
    IF (Test-Path "$Folder") {
        if (Test-Path "$Folder/.svn") {
            Set-Location "$Folder"
            [xml]$info = svn info --xml
            if ($info.info.entry.url -ne $Url) {
                Pop-Location
                Remove-Item $Folder -Force -Recurse
            }
        }
        else {
            Remove-Item $Folder -Force -Recurse
        }
    }
    Pop-Location
}

$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot

$RevisionObj = Get-Content -Path "$ClangbuilderRoot/config/revision.json" |ConvertFrom-Json

$LLVMRepositoriesRoot = "http://llvm.org/svn/llvm-project"
$OutDir = "$ClangbuilderRoot\out"



switch ($Branch) {
    {$_ -eq "Mainline"} {
        $UrlSuffix = "trunk"
        $SourcesDir = "$OutDir\trunk"
    } {$_ -eq "Stable"} {
        $StableName = $RevisionObj.Stable
        $UrlSuffix = "branches/$StableName"
        $SourcesDir = "$OutDir\$StableName"
    } {$_ -eq "Release"} {
        $TagName = $RevisionObj.Release
        $UrlSuffix = "tags/$TagName"
        $SourcesDir = "$OutDir\release"
        # check 
        CheckWorktree -Folder $SourcesDir -Url "$LLVMRepositoriesRoot/llvm/$UrlSuffix"
    }
}


Update-LLVM -URL "$LLVMRepositoriesRoot/llvm/$UrlSuffix" -Folder $SourcesDir
if (!(Test-Path "$SourcesDir\tools")) {
    Write-Output "Checkout llvm sources failed, exiting..."
    Exit
}

Set-Location "$SourcesDir\tools"
Update-LLVM -URL "$LLVMRepositoriesRoot/cfe/$UrlSuffix" -Folder "clang"
Update-LLVM -URL "$LLVMRepositoriesRoot/lld/$UrlSuffix" -Folder "lld"

IF ($LLDB) {
    Update-LLVM -URL "$LLVMRepositoriesRoot/lldb/$UrlSuffix" -Folder "lldb"
}
else {
    if (Test-Path "$SourcesDir\tools\lldb") {
        Remove-Item -Force -Recurse "$SourcesDir\tools\lldb"
    }
}

if (!(Test-Path "$SourcesDir/tools/clang/tools")) {
    Write-Output "Checkout clang sources failed, exiting..."
    Exit
}

Set-Location "$SourcesDir/tools/clang/tools"
Update-LLVM -URL "$LLVMRepositoriesRoot/clang-tools-extra/$UrlSuffix" -Folder "extra"
Set-Location "$SourcesDir/projects"
Update-LLVM -URL "$LLVMRepositoriesRoot/compiler-rt/$UrlSuffix" -Folder "compiler-rt"
Update-LLVM -URL "$LLVMRepositoriesRoot/libcxx/$UrlSuffix" -Folder "libcxx"
#Update-LLVM -URL "$LLVMRepositoriesRoot/openmp/$UrlSuffix" -Folder "openmp"
