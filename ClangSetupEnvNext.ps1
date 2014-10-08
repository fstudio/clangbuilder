<#############################################################################################################
# ClangSetup Environment vNext
#
#
##############################################################################################################>
IF($PSVersionTable.PSVersion.Major -lt 3)
{
Write-Host -ForegroundColor Red "ClangSetup Enviroment vNext Must Run on Windows PowerShell 3 or Later,`nYour PowerShell version Is : 
${Host}"
[System.Console]::ReadKey()
Exit
}

$CSEvNInvoke=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
Set-Location $CSEvNInvoke
IEX "${CSEvNInvoke}\bin\ClangSetupvNextUI.ps1"
IEX "${CSEvNInvoke}\bin\CSEvNInternal.ps1"
Show-LauncherWindow
IEX "${CSEvNInvoke}\bin\VisualStudioEnvNext.ps1"

Function Global:Check-Environment()
{
Find-VisualStudio|Out-Null
IF($Global:VS100B)
{
 Write-Host -ForegroundColor Green "Already installed Visual Studio 2010,Support X86 X64 | ClangSetup Disable Build;Enable CRT,C++STL`n"
}
IF($Global:VS110B)
{
 Write-Host -ForegroundColor Green "Already installed Visual Studio 2012,Support X86 X64 ARM | ClangSetup Enable: X86,X64 <3.6|Enable CRT,C++STL`n"
}
IF($Global:VS120B)
{
 Write-Host -ForegroundColor Green "Already installed Visual Studio 2013,Support X86 X64 ARM | ClangSetup Enable Build X86,X64;Enable CRT,C++ STL`n"
}
IF($Global:VS140B)
{
 Write-Host -ForegroundColor Green "Already installed Visual Studio 14,Support X86 X64 ARM  | ClangSetup Enable Build X86,X64,Disable C++STL`n"
}
IF($Global:VS150B)
{
 Write-Host -ForegroundColor Green "Already installed Visual Studio 15,Support X86 X64 ARM AArch64 | ClangSetup Disable `n"
}
}

#Show-OpenFileDialog
Check-Environment

IEX -Command "PowerShell -NoLogo"