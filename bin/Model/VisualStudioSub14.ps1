<#############################################################################
#  VisualStudioSub14.ps1
#  Note: Clang Auto Build Environment for Visual Studio 2015
#  Data:2015.01.02
#  Author:Force <forcemz@outlook.com>    
##############################################################################>
<#
In VisualStudio 2015 CTP 6 or Later ,C Header be move to %ProgramFiles%/Windows Kits/10
Include: Include/ucrt
LIB:winv10.0/ucrt/$target

#>
IF( $env:VS140COMNTOOLS -eq $null -or (Test-Path $env:VS140COMNTOOLS))
{
  Write-Host -ForegroundColor Red "Not Fond Vaild Install for Visual Studio 2015"
  return 
}

$VSInstallDIR=


#Step Get Uinversal C Runtime Defined

#Step Get C++ STL Defined

#Step Get Windows SDK Defined

#Step Get .NET PathInfo

