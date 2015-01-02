#PowerShell Profile[PowerShell 4.0]
#ForceStudio 
#2014.9
Set-Alias ll         Get-ChildItemColor  
 
if(!$global:WindowTitlePrefix) {
   # But if you're running "elevated" on vista, we want to show that ...
   if( ([System.Environment]::OSVersion.Version.Major -gt 5) -and ( # Vista and ...
         new-object Security.Principal.WindowsPrincipal (
            [Security.Principal.WindowsIdentity]::GetCurrent()) # current user is admin
            ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) )
   {
      $global:WindowTitlePrefix = "PowerShell@${Env:UserName} [Administator]"
   } else {
      $global:WindowTitlePrefix = "PowerShell@${Env:UserName}"
   }
}
  
Function prompt  
{  
 
    $ThisPath = $(Get-Location).toString()  
    $ThisPos = ($ThisPath).LastIndexOf("\") + 1  
    if( $ThisPos -eq ($ThisPath).Length ) { $ThisPath_tail = $ThisPath }  
    else { $ThisPath_tail = ($ThisPath).SubString( $ThisPos, ($ThisPath).Length - $ThisPos ) }  
    #$Host WindowTitle
    $Host.UI.RawUI.WindowTitle = "{0} - {1} ({2})" -f $global:WindowTitlePrefix,$pwd.Path,$pwd.Provider.Name
    #
    $Nesting = "$([char]0xB7)" * $NestedPromptLevel
    #
    Write-Host " "
    Write-Host ("[") -nonewline -foregroundcolor 'DarkGreen'  
    Write-Host ("$env:UserName") -nonewline -foregroundcolor 'Red'  
    Write-Host ("@") -nonewline -foregroundcolor 'Yellow'  
    Write-Host ("$env:UserDomain") -nonewline -foregroundcolor 'Cyan'  
    Write-Host ("|") -NoNewline -ForegroundColor 'Yellow'
    Write-Host ($ThisPath_tail) -nonewline -foregroundcolor 'DarkRed'  
    Write-Host ("]>") -nonewline -foregroundcolor 'DarkGreen'  
    return " "  
}  
 
  
function Show-Color( [System.ConsoleColor] $color )  
{  
    $fore = $Host.UI.RawUI.ForegroundColor  
    $Host.UI.RawUI.ForegroundColor = $color  
    #$Host.UI.RawUI.BackgroundColor=`#1A1A1A
    echo ($color).toString()  
    $Host.UI.RawUI.ForegroundColor = $fore  
}  
  
function Show-AllColor  
{  
    Show-Color('Black')  
    Show-Color('DarkBlue')  
    Show-Color('DarkGreen')  
    Show-Color('DarkCyan')  
    Show-Color('DarkRed')  
    Show-Color('DarkMagenta')  
    Show-Color('DarkYellow')  
    Show-Color('Gray')  
    Show-Color('DarkGray')  
    Show-Color('Blue')  
    Show-Color('Green')  
    Show-Color('Cyan')  
    Show-Color('Red')  
    Show-Color('Magenta')  
    Show-Color('Yellow')  
    Show-Color('White')  
}  