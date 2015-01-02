<#############################################################################
#  VisualStudioSub11.ps1
#  Note: Clang Auto Build Environment for Visual Studio 2012
#  Data:2015.01.02
#  Author:Force <forcemz@outlook.com>    
##############################################################################>

IF( $env:VS110COMNTOOLS -eq $null -or (Test-Path $env:VS110COMNTOOLS))
{
  Write-Host -ForegroundColor Red "Not Fond Vaild Install for Visual Studio 2012"
  return 
}