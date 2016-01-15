<#############################################################################
#  RepositoryCheckout.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>
##############################################################################>
$SelfFolder=$PSScriptRoot;

Function Global:Restore-Repository{
param(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Checkout URL")]
[ValidateNotNullorEmpty()]
[String]$URL,
[Parameter(Position=1,Mandatory=$True,HelpMessage="Enter Checkout Folder")]
[ValidateNotNullorEmpty()]
[String]$Folder
)
Push-Location $PWD
IF((Test-Path "$Folder") -and (Test-Path "$Folder/.svn")){
    Set-Location "$Folder"
    &svn cleanup .
    &svn up .
}ELSE{
    IF((Test-Path "$Folder")){
        Remove-Item -Force -Recurse "$Folder/.svn"
    }
    &svn co $URL "$Folder"
}
Pop-Location
}
