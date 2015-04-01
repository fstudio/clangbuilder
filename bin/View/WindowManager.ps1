<#############################################################################
#  WindowManager.ps1
#  Note: Clang Auto Build Window Manager UI Frame.
#  Data:2015.01.01
#  Author:Force <forcemz@outlook.com>    
##############################################################################>



Function Global:Show-LauncherWindowUI{
$xaml = @"
<Window
 xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'>

 <Border BorderThickness="25" BorderBrush="White" CornerRadius="9" Background='White'>
  <StackPanel>
   <Label FontSize="50" FontFamily='Segoe UI' Background='White' Foreground='Black' BorderThickness='1'>
    This Report 
   </Label>

   <Label HorizontalAlignment="Center" FontSize="15" FontFamily='Consolas' Background='Aqua' Foreground='Black' BorderThickness='0'>
    ClangSetup vNext
   </Label>
  </StackPanel>
 </Border>
</Window>
"@
Add-Type -assemblyName PresentationFramework
$reader = [System.XML.XMLReader]::Create([System.IO.StringReader] $xaml)
$window = [System.Windows.Markup.XAMLReader]::Load($reader)
$Window.AllowsTransparency = $True
$window.SizeToContent = 'WidthAndHeight'
$window.ResizeMode = 'NoResize'
$Window.Opacity = .7
$window.Topmost = $true
$window.WindowStartupLocation = 'Manual'
$window.WindowStyle = 'None'
# show message for 5 seconds:
#$Host.UI.RawUI.WindowPosition
$null = $window.Show()
Start-Sleep -Seconds 2
$window.Close()
}

Show-LauncherWindowUI




