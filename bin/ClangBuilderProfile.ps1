# $userToFind = $args[0] 
# $administratorsAccount = Get-WmiObject Win32_Group -filter "LocalAccount=True AND SID='S-1-5-32-544'" 
# $administratorQuery = "GroupComponent = `"Win32_Group.Domain='" + $administratorsAccount.Domain + "',NAME='" + $administratorsAccount.Name + "'`"" 
# $user = Get-WmiObject Win32_GroupUser -filter $administratorQuery | select PartComponent |where {$_ -match $userToFind} 
# $user 

Function Test-IsAdministrator{
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole] "Administrator")
}

function prompt {

}