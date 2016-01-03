<#############################################################################
#  RestoreClangMainline.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>    
##############################################################################>

[System.Boolean] $IsEnabledLLDB=$FALSE

IF($args.Count -ge 1){
    IF($args[0] -eq "--with-lldb"){
        $IsEnabledLLDB=$TRUE
    }
}

$SelfFolder=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
IEX -Command "$SelfFolder/RepositoryCheckout.ps1"

$ClangbuilderRoot=Split-Path -Parent $SelfFolder
$BuildFolder="$ClangbuilderRoot/out"
$MainlineFolder="$BuildFolder/mainline"
$LLVMRepositoriesRoot="http://llvm.org/svn/llvm-project"

IF(!(Test-Path $BuildFolder)){
    mkdir $BuildFolder
}

Set-Location $BuildFolder

$PushPWD=Get-Location

Restore-Repository -URL "$LLVMRepositoriesRoot/llvm/trunk" -Folder "mainline"
if((Test-Path "$BuildFolder/mainline/tools")){
Write-Host "Checkout LLVM Failed"
Exit
}
Set-Location "$BuildFolder/mainline/tools"
Restore-Repository -URL "$LLVMRepositoriesRoot/cfe/trunk" -Folder "clang"
Restore-Repository -URL "$LLVMRepositoriesRoot/lld/trunk" -Folder "lld"
IF($IsEnabledLLDB){
    Restore-Repository -URL "$LLVMRepositoriesRoot/lldb/trunk" -Folder "lldb"
}else{
    Remove-Item -Force -Recurse "$BuildFolder/mainline/tools/lldb"
}
if((Test-Path "$BuildFolder/mainline/tools/clang/tools")){
Write-Host "Checkout Clang Failed"
Exit
}
Set-Location "$BuildFolder/mainline/tools/clang/tools"
Restore-Repository -URL "$LLVMRepositoriesRoot/clang-tools-extra/trunk" -Folder "extra"
Set-Location "$BuildFolder/mainline/projects"
Restore-Repository -URL "$LLVMRepositoriesRoot/compiler-rt/trunk" -Folder "compiler-rt"

Set-Location $PushPWD

