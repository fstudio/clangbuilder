<#############################################################################
#  ClangBuilderUtility.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>    
##############################################################################>

Function Reset-Environment{
    $env:Path="${env:windir};${env:windir}\System32;${env:windir}\System32\Wbem;${env:windir}\System32\WindowsPowerShell\v1.0"
}

Function Clear-BuildWorkdir{
    $ClangbuilderRoot=Split-Path -Parent $PSScriptRoot
    $LockFile="${ClangbuilderRoot}\out\workdir\build.lock.json"
    if(Test-Path $LockFile){
        
    }
}