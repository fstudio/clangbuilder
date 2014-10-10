
$Global:CSNUIInvoke=Split-Path -Parent $MyInvocation.MyCommand.Definition
$env:PSModulePath="$env:PSModulePath;${CSNUIInvoke}\Modules"
<#Import-Module WPK
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows')|Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('System.Diagnostics')|Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('System.XML')|Out-Null
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Markup')|Out-Null
#>

Function Global:Show-LauncherWindow{

#[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Markup.XAMLReader')|Out-Null
$xaml = @"
<Window
 xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'>

 <Border BorderThickness="25" BorderBrush="White" CornerRadius="9" Background='White'>
  <StackPanel>
   <Label FontSize="50" FontFamily='Segoe UI' Background='White' Foreground='Black' BorderThickness='1'>
    ClangSetup Environment vNext
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
$window.WindowStartupLocation = 'CenterScreen'
$window.WindowStyle = 'None'
# show message for 5 seconds:
#$Host.UI.RawUI.WindowPosition
$null = $window.Show()
Start-Sleep -Seconds 2
$window.Close()
}



Function Global:Get-ReadMeWindow(){
$ReadMeDir=Split-Path -Parent $CSNUIInvoke
$text = Get-Content "${CSNUIInvoke}\ReadMe.txt" -ReadCount 0 | Out-String
Add-Type -AssemblyName Microsoft.PowerShell.GraphicalHost
$HelpWindow = New-Object Microsoft.Management.UI.HelpWindow $text -Property @{
    Title="ClangSetup vNext ReadMe"
    Background='#011f51'
    FontSize='14'
    Foreground='#FFFFFFFF'
}

$HelpWindow.ShowDialog()
}

Function Global:Show-OpenFileDialog
{
  param
  (
    $StartFolder = [Environment]::GetFolderPath('MyDocuments'),

    $Title = 'Open Files',
    
    $Filter = 'All|*.*|Scripts|*.ps1|Texts|*.txt|Logs|*.log'
  )
  
  
  Add-Type -AssemblyName PresentationFramework
  
  $dialog = New-Object -TypeName Microsoft.Win32.OpenFileDialog
  
  
  $dialog.Title = $Title
  $dialog.InitialDirectory = $StartFolder
  $dialog.Filter = $Filter
  
  
  $resultat = $dialog.ShowDialog()
  if ($resultat -eq $true)
  {
    $dialog.FileName
  }
}
Function Global:Out-ClangSetupTipsVoice([String]$voicestr){
Add-Type -AssemblyName System.Speech

$synthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
$synthesizer.Speak($voicestr)
}

Function Global:Select-MenuShow(){
$title = "ClangSetup vNext Select"
$message = "Do you want to Create Shortcut ?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "continue."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "End options"
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $Host.UI.PromptForChoice($title, $message, $options, 0) 

switch ($result)
    {
        0 {"You selected Yes."
           Echo "Yes"
          }
        1 {"You selected No."}
    }
}

Function Global:New-PopuShow {

<#
.Synopsis
Display a Popup Message
.Description
This command uses the Wscript.Shell PopUp method to display a graphical message
box. You can customize its appearance of icons and buttons. By default the user
must click a button to dismiss but you can set a timeout value in seconds to 
automatically dismiss the popup. 

The command will write the return value of the clicked button to the pipeline:
  OK     = 1
  Cancel = 2
  Abort  = 3
  Retry  = 4
  Ignore = 5
  Yes    = 6
  No     = 7

If no button is clicked, the return value is -1.
.Example
PS C:\> new-popup -message "The update script has completed" -title "Finished" -time 5

This will display a popup message using the default OK button and default 
Information icon. The popup will automatically dismiss after 5 seconds.
.Notes
Last Updated: April 8, 2013
Version     : 1.0

.Inputs
None
.Outputs
integer

Null   = -1
OK     = 1
Cancel = 2
Abort  = 3
Retry  = 4
Ignore = 5
Yes    = 6
No     = 7
#>

Param (
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a message for the popup")]
[ValidateNotNullorEmpty()]
[string]$Message,
[Parameter(Position=1,Mandatory=$True,HelpMessage="Enter a title for the popup")]
[ValidateNotNullorEmpty()]
[string]$Title,
[Parameter(Position=2,HelpMessage="How many seconds to display? Use 0 require a button click.")]
[ValidateScript({$_ -ge 0})]
[int]$Time=0,
[Parameter(Position=3,HelpMessage="Enter a button group")]
[ValidateNotNullorEmpty()]
[ValidateSet("OK","OKCancel","AbortRetryIgnore","YesNo","YesNoCancel","RetryCancel")]
[string]$Buttons="OK",
[Parameter(Position=4,HelpMessage="Enter an icon set")]
[ValidateNotNullorEmpty()]
[ValidateSet("Stop","Question","Exclamation","Information" )]
[string]$Icon="Information"
)

#convert buttons to their integer equivalents
Switch ($Buttons) {
    "OK"               {$ButtonValue = 0}
    "OKCancel"         {$ButtonValue = 1}
    "AbortRetryIgnore" {$ButtonValue = 2}
    "YesNo"            {$ButtonValue = 4}
    "YesNoCancel"      {$ButtonValue = 3}
    "RetryCancel"      {$ButtonValue = 5}
}

#set an integer value for Icon type
Switch ($Icon) {
    "Stop"        {$iconValue = 16}
    "Question"    {$iconValue = 32}
    "Exclamation" {$iconValue = 48}
    "Information" {$iconValue = 64}
}

#create the COM Object
Try {
    $wshell = New-Object -ComObject Wscript.Shell -ErrorAction Stop
    #Button and icon type values are added together to create an integer value
    $wshell.Popup($Message,$Time,$Title,$ButtonValue+$iconValue)
}
Catch {
    #You should never really run into an exception in normal usage
    Write-Warning "Failed to create Wscript.Shell COM object"
    Write-Warning $_.exception.message
}

} #end function

Function Global:Bmp2Icons([string]$bmpPath,[string]$iconPath)
{
    Add-Type -AssemblyName "System.Drawing"
    $bmp=[Drawing.Bitmap]::fromFile($bmpPath)
    $icon=[Drawing.icon]::FromHandle($bmp.GetHicon())
    $fs=New-Object IO.FileStream $iconPath,"OpenOrCreate"
    $icon.save($fs)
    $fs.Close()
    $icon.Dispose()
 
}
 

