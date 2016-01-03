<#############################################################################
#  ClangRevision.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>    
##############################################################################>
$SelfFolder=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)

Function Global:Restore-Repository{
param(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Checkout URL")]
[ValidateNotNullorEmpty()]
[String]$URL,
[Parameter(Position=1,Mandatory=$True,HelpMessage="Enter Checkout Folder")]
[ValidateNotNullorEmpty()]
[String]$Folder
)
$PushPWD=Get-Location
IF((Test-Path "$Folder") -and (Test-Path "$Folder/.svn")){
    Set-Location "$Folder"
    Invoke-Expression -Command "svn cleanup ."
    Invoke-Expression -Command "svn up ."
}ELSE{
    IF((Test-Path "$Folder")){
        Remove-Item -Force -Recurse "$Folder/.svn"
    }
    Invoke-Expression -Command "svn co $URL $Folder"
}
Set-Location $PushPWD
}


