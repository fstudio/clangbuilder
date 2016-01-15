<#############################################################################
#  MessageThrow.ps1
#  Note: Clang Auto Build Message Throw API
#  Data:2015.01.01
#  Author:Force <forcemz@outlook.com>    
##############################################################################>

Function Out-MessageThrow
{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a message for the Message Throw")]
        [ValidateNotNullorEmpty()]
        [string]$Message,
        [Parameter(Position=2,HelpMessage="Please Input Error Code.")]
        [int]$ErrorCode=-1
        )
        Write-Error  $Message
        [System.Console]::ReadKey()
        exit $ErrorCode
}

Function Show-MessageWindow{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a message for the Message Throw")]
        [ValidateNotNullorEmpty()]
        [string]$Message,
        [Parameter(Position=2,HelpMessage="Please Select Message ICON.")]
        [ValidateScript({$_ -ge 0})]
        [int]$MessageIcon=1,
        [Parameter(Position=2,HelpMessage="Please Input Error Code.")]
        [int]$ErrorCode=-1
        )
}