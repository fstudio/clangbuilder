<#
	.SYNOPSIS
		WPF XAML Codes in PowerShell.
	
	.DESCRIPTION
		An Attempt to use XAML Codes for GUI design.
		This script gets Service, Process and OS information.
		The Output Files will be saved in ${env:TEMP}\Temp
		
	.NOTE
		Choose the location where you have desired access to save the output file and to create a STYLE.CSS
		
	.DEVELOPER
	Chendrayan Venkatesan
	
#>

Add-Type -AssemblyName PresentationFramework
[xml]$xaml = 
@"
<Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PowerShell WPF" Height="244" Width="525" FontFamily="Segoe UI" FontWeight="Bold" ResizeMode="NoResize">
    <Grid Background="#6CA6CD">
        <GroupBox Header="Tools" Height="129" HorizontalAlignment="Left" Margin="142,20,0,0" Name="groupBox1" VerticalAlignment="Top" Width="200">
            <Grid>
                <Button Content="Services" Height="23" HorizontalAlignment="Left" Margin="6,27,0,0" Name="Services" VerticalAlignment="Top" Width="75" />
                <Button Content="Process" Height="23" HorizontalAlignment="Left" Margin="107,27,0,0" Name="Process" VerticalAlignment="Top" Width="75" />
                <Button Content="OS" Height="23" HorizontalAlignment="Left" Margin="58,66,0,0" Name="OS" VerticalAlignment="Top" Width="75" />
            </Grid>
        </GroupBox>
        <Label Content="Designed and Developed by Free Lancer" Height="28" HorizontalAlignment="Left" Margin="288,165,0,0" Name="label1" VerticalAlignment="Top" />
    </Grid>
</Window>

"@

if(!(Test-Path -Path ${env:TEMP}\Style.css))
{
New-Item -Value " body {
font-family:Segoe UI;
 font-size:10pt;
background-image:url('${env:TEMP}\Images\CookieAuth.jpg'); 
}
th { 
background-color:black;

color:white;
}
td {
 background-color:#19fff0;
color:black;" -Path ${env:TEMP}\style.CSS -Confirm:$false -ItemType File

}

Function Servicereport()
{
$system = Get-Wmiobject -Class Win32_Service | ConvertTo-Html -Fragment
ConvertTo-Html -Body $system -CssUri ${env:TEMP}\style.CSS -Title "Services" | Out-File ${env:TEMP}\Services.html
Start-Sleep 2
Invoke-Item ${env:TEMP}\Services.HTML
}

Function Processreport()
{
$Process = Get-Wmiobject -Class Win32_Process | Select Caption , Path , Name , ProcessID | ConvertTo-Html -Fragment
ConvertTo-Html -Body $Process -CssUri ${env:TEMP}\style.CSS -Title "Process" | Out-File ${env:TEMP}\Process.html
Start-Sleep 2
Invoke-Item ${env:TEMP}\Process.HTML
}

Function OS()
{
$OS = Get-WmiObject -Class Win32_OperatingSystem | ConvertTo-Html -Fragment
ConvertTo-Html -Body $OS -CssUri ${env:TEMP}\style.CSS -Title "OS Information" | Out-File ${env:TEMP}\OS.Html
Start-Sleep 2
Invoke-Item ${env:TEMP}\OS.HTML 
}

$reader=(New-Object System.Xml.XmlNodeReader $xaml)
$Window=[Windows.Markup.XamlReader]::Load( $reader )

$button1 = $Window.FindName("Services")
$button2 = $Window.FindName("Process")
$button3 = $Window.FindName("OS")
$Method1=$button1.add_click
$Method2=$button2.add_click
$Method3=$button3.add_click
$Method1.Invoke({Servicereport})
$Method2.Invoke({Processreport})
$Method3.Invoke({OS})


$Window.ShowDialog() | Out-Null