<#
# Add ExclusionPath to Windows Defender 
# Support Windows 8.1 or Later
# See https://technet.microsoft.com/en-us/library/dn433281.aspx
#>
$ClangBuilderRoot=Split-Path -Parent $PSScriptRoot
IF($PSVersionTable.BuildVersion.Build -lt 6300){
    Write-Error "Add-MpPreference Cmdlet Require Windows 8.1 or Later "
    Exit
}
$windowsIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$windowsPrincipal = [Security.Principal.WindowsPrincipal]$windowsIdentity

if( -not $windowsPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Error "Add-MpPreference Require Administrator."
    Exit
}

Add-MpPreference -ExclusionPath $ClangBuilderRoot
