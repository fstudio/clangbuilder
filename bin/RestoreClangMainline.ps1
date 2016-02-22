<#############################################################################
#  RestoreClangMainline.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>
##############################################################################>
param(
    [Switch]$LLDB
)
. "$PSScriptRoot/RepositoryCheckout.ps1"

$ClangbuilderRoot=Split-Path -Parent $PSScriptRoot
$BuildFolder="$ClangbuilderRoot\out"
$MainlineFolder="$BuildFolder\mainline"
Write-Output "Mainline Source Folder: $MainlineFolder"
$LLVMRepositoriesRoot="http://llvm.org/svn/llvm-project"

IF(!(Test-Path $BuildFolder)){
    mkdir -Force $BuildFolder
}
Push-Location $PWD
Set-Location $BuildFolder

Restore-Repository -URL "$LLVMRepositoriesRoot/llvm/trunk" -Folder "mainline"
if(!(Test-Path "$BuildFolder/mainline/tools")){
    Write-Error "Checkout LLVM Failed"
    Exit
}

Set-Location "$BuildFolder/mainline/tools"
Restore-Repository -URL "$LLVMRepositoriesRoot/cfe/trunk" -Folder "clang"
Restore-Repository -URL "$LLVMRepositoriesRoot/lld/trunk" -Folder "lld"

IF($LLDB){
    Restore-Repository -URL "$LLVMRepositoriesRoot/lldb/trunk" -Folder "lldb"
}else{
    if(Test-Path "$BuildFolder/mainline/tools/lldb"){
        Remove-Item -Force -Recurse "$BuildFolder/mainline/tools/lldb"
    }
}

if(!(Test-Path "$BuildFolder/mainline/tools/clang/tools")){
    Write-Error "Checkout Clang Failed"
    Exit
}

Set-Location "$BuildFolder/mainline/tools/clang/tools"
Restore-Repository -URL "$LLVMRepositoriesRoot/clang-tools-extra/trunk" -Folder "extra"
Set-Location "$BuildFolder/mainline/projects"
Restore-Repository -URL "$LLVMRepositoriesRoot/compiler-rt/trunk" -Folder "compiler-rt"

Pop-Location
