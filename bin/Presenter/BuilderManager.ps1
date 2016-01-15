<#############################################################################
#  PackageManager.ps1
#  Note: Clang Auto Build Builder Manager  
#  Data:2015.01.01
#  Author:Force <forcemz@outlook.com>    
##############################################################################>



Function RunningBuilder{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a message for the Message Throw")]
        [ValidateNotNullorEmpty()]
        [string]$Message
        )
}
