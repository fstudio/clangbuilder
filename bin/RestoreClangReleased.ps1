<#############################################################################
#  RestoreClangReleased.ps1
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

$RemoveOldCheckout=$FALSE
IF($args.Count -ge 2){
    IF($args[1] -eq "--co"){
        $RemoveOldCheckout=$TRUE
    }
}

$SelfFolder=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
IEX -Command "$SelfFolder/RepositoryCheckout.ps1"
$ClangbuilderRoot=Split-Path -Parent $SelfFolder
$BuildFolder="$ClangbuilderRoot/out"
$ReleaseRevFolder="$BuildFolder/release"
$LLVMRepositoriesRoot="http://llvm.org/svn/llvm-project"
$ReleaseRevision="RELEASE_371/final"

IF(!(Test-Path $BuildFolder)){
    mkdir $BuildFolder
}

$PushPWD=Get-Location
Set-Location $BuildFolder
IF((Test-Path "$BuildFolder/release") -and $RemoveOldCheckout){
    Remove-Item -Force -Recurse "$BuildFolder/release"
}
Restore-Repository -URL "$LLVMRepositoriesRoot/llvm/tags/$ReleaseRevision" -Folder "release"
Set-Location "$BuildFolder/release/tools"
Restore-Repository -URL "$LLVMRepositoriesRoot/cfe/tags/$ReleaseRevision" -Folder "clang"
Restore-Repository -URL "$LLVMRepositoriesRoot/lld/tags/$ReleaseRevision" -Folder "lld"
IF($IsEnabledLLDB){
    Restore-Repository -URL "$LLVMRepositoriesRoot/lldb/tags/$ReleaseRevision" -Folder "lldb"
}else{
    Remove-Item -Force -Recurse "$BuildFolder/release/tools/lldb"
}
Set-Location "$BuildFolder/release/tools/clang/tools"
Restore-Repository -URL "$LLVMRepositoriesRoot/clang-tools-extra/tags/$ReleaseRevision" -Folder "extra"
Set-Location "$BuildFolder/release/projects"
Restore-Repository -URL "$LLVMRepositoriesRoot/compiler-rt/tags/$ReleaseRevision" -Folder "compiler-rt"

Set-Location $PushPWD
