<#############################################################################
#  WindowManager.ps1
#  Note: Clang Auto Build Window Manager UI Frame.
#  Data:2015.01.01
#  Author:Force <forcemz@outlook.com>    
##############################################################################>

Function Global:Show-LauncherWindow{
    param(
        [int]$Timeout=1
    )
$xaml = @"
<Window
 xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'>
 <Border BorderThickness="25" BorderBrush="White" CornerRadius="100" Background='White'>
  <StackPanel>
   <Label FontSize="50" FontFamily='Segoe UI' Background='White' Foreground='Black' BorderThickness='1'>
    Clangbuilder
   </Label>
   <Label HorizontalAlignment="Center" FontSize="15" FontFamily='Segoe UI' 
    Background='Aqua' Foreground='Black' BorderThickness='0'>
    Clangbuilder Initializing ...
   </Label>
  </StackPanel>
 </Border>
</Window>
"@
Add-Type -assemblyName PresentationFramework
$reader = [System.XML.XMLReader]::Create([System.IO.StringReader] $xaml)
$window = [System.Windows.Markup.XAMLReader]::Load($reader)
$window.AllowsTransparency = $True
#$window.Icon="$PSScriptRoot/Notifications.ico"
$window.SizeToContent = 'WidthAndHeight'
$window.ResizeMode = 'NoResize'

$Mebs=Get-Member -InputObject $window

# foreach($i in $Mebs){
#     Write-Host $i
# }

#$Window.Opacity = .9
$window.Topmost = $true
$window.WindowStartupLocation = 'CenterScreen'
$window.WindowStyle = 'None'
# show message for 5 seconds:
#$Host.UI.RawUI.WindowPosition
$null = $window.Show()
Start-Sleep -Milliseconds $Timeout 
$window.Close()
}


Show-LauncherWindow -Timeout 500




