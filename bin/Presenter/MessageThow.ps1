<#############################################################################
#  MessageThrow.ps1
#  Note: Clang Auto Build Message Throw API
#  Data:2015.01.01
#  Author:Force <forcemz@outlook.com>    
##############################################################################>

Function Global:Print-MessageThrow
{
param(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a message for the Message Throw")]
[ValidateNotNullorEmpty()]
[string]$Message,
[Parameter(Position=2,HelpMessage="Please Input Error Code.")]
[ValidateScript({$_ -ge 0})]
[int]$ErrorCode=-1
)
Write-Host -BackgroundColor Red "$Message`n"
[System.Console]::ReadKey()
exit $ErrorCode
}

Function Global:Show-MessageWindow{
param(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a message for the Message Throw")]
[ValidateNotNullorEmpty()]
[string]$Message,
[Parameter(Position=2,HelpMessage="Please Select Message ICON.")]
[ValidateScript({$_ -ge 0})]
[int]$MessageIcon=1,
[Parameter(Position=2,HelpMessage="Please Input Error Code.")]
[ValidateScript({$_ -ge 0})]
[int]$ErrorCode=-1
)


}