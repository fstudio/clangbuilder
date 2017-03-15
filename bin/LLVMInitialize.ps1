#!/usr/bin/env powershell
# Initialize or update llvm clang sources
param(
    [Switch]$LLDB,
    [Switch]$Mainline
)

Function Update-LLVM{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Checkout URL")]
        [ValidateNotNullorEmpty()]
        [String]$URL,
        [Parameter(Position=1,Mandatory=$True,HelpMessage="Enter Checkout Folder")]
        [ValidateNotNullorEmpty()]
        [String]$Folder
    )
    Push-Location $PWD
    IF((Test-Path "$Folder") -and (Test-Path "$Folder/.svn")){
        Set-Location "$Folder"
        Write-Host "Update $Folder"
        &svn cleanup .
        &svn up .
    }ELSE{
        IF((Test-Path "$Folder")){
            Remove-Item -Force -Recurse "$Folder"
        }
        Write-Host "Checkout $Folder"
        &svn co $URL "$Folder"
    }
    Pop-Location
}

Function CheckWorktree{
    param(
        [String]$Folder,
        [String]$Url
    )
    Push-Location $PWD
    IF(Test-Path "$Folder"){
        if(Test-Path "$Folder/.svn"){
            Set-Location "$Folder"
            [xml]$info=svn info --xml
            if($info.info.entry.url -ne $Url){
                Pop-Location
                Remove-Item $Folder -Force -Recurse
            }
        }else{
            Remove-Item $Folder -Force -Recurse
        }
    }
    Pop-Location
}

$ClangbuilderRoot=Split-Path -Parent $PSScriptRoot
$LatestObj=Get-Content -Path "$ClangbuilderRoot/config/latest.json" |ConvertFrom-Json

$TagName=$LatestObj.Suffix
$LLVMRepositoriesRoot="http://llvm.org/svn/llvm-project"
$CurrentDir=Get-Location
$OutDir="$ClangbuilderRoot\out"


if($Mainline){
    $UrlSuffix="trunk"
    $SourcesDir="$OutDir\mainline"
}else{
    $UrlSuffix="tags/$TagName"
    $SourcesDir="$OutDir\release"
    CheckWorktree -Folder $SourcesDir -Url "$LLVMRepositoriesRoot/llvm/$UrlSuffix"
}


Update-LLVM -URL "$LLVMRepositoriesRoot/llvm/$UrlSuffix" -Folder $SourcesDir
if(!(Test-Path "$SourcesDir\tools")){
    Write-Output "Checkout LLVM Failed"
    Exit
}

Set-Location "$SourcesDir\tools"
Update-LLVM -URL "$LLVMRepositoriesRoot/cfe/$UrlSuffix" -Folder "clang"
Update-LLVM -URL "$LLVMRepositoriesRoot/lld/$UrlSuffix" -Folder "lld"

IF($LLDB){
    Update-LLVM -URL "$LLVMRepositoriesRoot/lldb/$UrlSuffix" -Folder "lldb"
}else{
    if(Test-Path "$SourcesDir\tools\lldb"){
        Remove-Item -Force -Recurse "$SourcesDir\tools\lldb"
    }
}

if(!(Test-Path "$SourcesDir/tools/clang/tools")){
    Write-Output "Checkout Clang Failed"
    Exit
}

Set-Location "$SourcesDir/tools/clang/tools"
Update-LLVM -URL "$LLVMRepositoriesRoot/clang-tools-extra/$UrlSuffix" -Folder "extra"
Set-Location "$SourcesDir/projects"
Update-LLVM -URL "$LLVMRepositoriesRoot/compiler-rt/$UrlSuffix" -Folder "compiler-rt"
Update-LLVM -URL "$LLVMRepositoriesRoot/openmp/$UrlSuffix" -Folder "openmp"
