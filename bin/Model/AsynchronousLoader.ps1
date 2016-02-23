<#############################################################################
#  AsynchronousLoader.ps1
#  Note: Clang Auto Build Asynchronous Loader API
#  Date:2016.01.01
#  Author:Force <forcemz@outlook.com>    
##############################################################################>

. "$PSScriptRoot/VisualStudioShared.ps1"

$VSInstallRoot=Get-RegistryValue2 -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\VisualStudio\SxS\VS7' -Key '14.0'

Write-Output $VSInstallRoot
