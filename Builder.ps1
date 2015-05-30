<#############################################################################
#  Builder.ps1
#  Note: Clang Auto Build TaskScheduler
#  Data:2015 04
#  Author:Force <forcemz@outlook.com>
##############################################################################>
IF($PSVersionTable.PSVersion.Major -lt 3)
{
Write-Host -ForegroundColor Red "ClangSetup Builder PowerShell vNext Must Run on Windows PowerShell 3 or Later,`nYour PowerShell version Is : 
${Host}"
[System.Console]::ReadKey()
Exit
}

$WindowTitlePrefix=" ClangSetup PowerShell Builder"
Write-Host "ClangSetup Auto Builder [PowerShell] tools"
Write-Host "Copyright $([Char]0xA9) 2015 FroceStudio All Rights Reserved."

Function Global:Run-BuilderMain()
{
    param
    (
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter Builder Param")]
        [ValidateNotNullorEmpty()]
        [String]$Version="VS120",
        [String]$Target="X86",
        [String]$BuildType="Release"
    )
    Echo $Version $Target $BuildType
}
Run-BuilderMain
