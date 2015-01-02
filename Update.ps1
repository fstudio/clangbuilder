<#
#
#
#
#>
$Updateroot=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)

####WPF
Add-Type -AssemblyName PresentationFramework
[xml]$xaml = 
@"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="ClangSetup vNext upgrade confirmation" Height="200" Width="520" FontFamily="Segoe UI"  ResizeMode="NoResize">
    <Grid>
            <Label Content="Select Upgrade to Update ClangSetup vNext" FontSize="14px" Height="32" HorizontalAlignment="Left" Margin="20,20,20,0" Name="label1" VerticalAlignment="Top" />
            <Label Content="Select 'Reset' Is Upgrade and Reset ClangSetup vNext ,Other Cancle" FontSize="14px" Height="32" HorizontalAlignment="Left" Margin="20,40,20,0" Name="label2" VerticalAlignment="Top" />
            <Button Content="Upgrade" Height="25" HorizontalAlignment="Left" Margin="30,100,0,0" Name="Upgrade" VerticalAlignment="Top" Width="120" />
            <Button Content="Reset" Height="25" HorizontalAlignment="Left" Margin="180,100,0,0" Name="Reset" VerticalAlignment="Top" Width="120" />
            <Button Content="Cancle" Height="25" HorizontalAlignment="Left" Margin="330,100,0,0" Name="Cancle" VerticalAlignment="Top" Width="120" />
    </Grid>
</Window>

"@

############Parse Module
Function UpgradeClangSetup()
{
  $Window.Close()
  Write-Host "You Select is Upgrade,Shell will Upgrade ClangSetup Environment vNext."
  IEX "${Updateroot}\bin\Installer\Update.ps1"
  Get-GithubUpdatePackage $Updateroot
  Invoke-Expression   "${Updateroot}\tools\Install.ps1"
}

Function UpgradeAndReset()
{
  $Window.Close()
  Write-Host "You Select is Reset,Shell will execute resetting ClangSetup Environment vNext.
  First Upgrade PowerShell Script From Github,
  Second Run InstallClangSetupvNext.ps1"
  IEX "${Updateroot}\bin\Installer\Reset.ps1"
}

Function CancleOptions()
{
  $Window.Close()
  Write-Host "The operation was canceled"
  Write-Host "Enter any key to continue"
  [System.Console]::ReadKey()|Out-Null
}

$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$Window=[Windows.Markup.XamlReader]::Load( $reader )

$button1 = $Window.FindName("Upgrade")
$button2 = $Window.FindName("Reset")
$button3 = $Window.FindName("Cancle")
$Method1=$button1.add_click
$Method2=$button2.add_click
$Method3=$button3.add_click
$Method1.Invoke({UpgradeClangSetup})
$Method2.Invoke({UpgradeAndReset})
$Method3.Invoke({CancleOptions})


$Window.ShowDialog() | Out-Null



