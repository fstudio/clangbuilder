<#############################################################################
#  ClangBuilderManager.ps1
#  Note: Clang Auto Build TaskScheduler
#  Data:2014 08
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


$VSHost="120"
[System.Boolean] $NmakeEnable=$FALSE



Function Call-VisualStudioSub
{
param(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter VisualStudio Version ")]
[ValidateNotNullorEmpty()]
[int]$VSMark,
[Parameter(Position=1,HelpMessage="Select Build Platform,x86,x64,ARM")]
[String]$Platform
)
IF( $VSMark -eq 11)
{
 IF(($env:VS110COMNTOOLS -ne $null) -and (Test-Path $env:VS110COMNTOOLS))
 {
  return $TRUE
 }
  return $FALSE
}

IF($VSMark -eq  12)
{
 IF(($env:VS120COMNTOOLS -ne $null) -and (Test-Path $env:VS120COMNTOOLS))
 {
  return $TRUE
 }
  return $FALSE
}

IF($VSMark -eq 14)
{
 IF(($env:VS140COMNTOOLS -ne $null) -and (Test-Path $env:VS140COMNTOOLS))
 {
  return $TRUE
 }
  return $FALSE
}

IF($VSMark -eq 15)
{
 IF(($env:VS150COMNTOOLS -ne $null) -and (Test-Path $env:VS150COMNTOOLS))
 {
  return $TRUE
 }
  return $FALSE
}
return $FALSE
}

<#----------Test.
Call-VisualStudioSub 11
Call-VisualStudioSub 12
Call-VisualStudioSub 13
Call-VisualStudioSub 14
Call-VisualStudioSub 15#>