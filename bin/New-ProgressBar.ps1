<#
.SYNOPSIS  
    This script is used to create a  progress bar
.DESCRIPTION  
    This script uses a Powershell Runspace to create and manage a WPF progress bar that can be manipulated to show
    script progress and details.  There are no arguments for this script because it is just an example of how this can be done.  
    The components within the script are what's important for setting this up for your own purposes.
.NOTES  
    Version		: 1.0
    Author		: Rhys Edwards
    Email		: powershell@nolimit.to  
    Credit Due	: Boe Prox wrote in detail about this method of using runspaces and forms, I just applied it to a very 
                                        common problem
    Link		: http://learn-powershell.net/2012/10/14/powershell-and-wpf-writing-data-to-a-ui-from-a-different-runspace/
#>

Begin {

# Function to facilitate updates to controls within the window
Function Update-Window {
    Param (
        $Control,
        $Property,
        $Value,
        [switch]$AppendContent
    )

   # This is kind of a hack, there may be a better way to do this
   If ($Property -eq "Close") {
      $syncHash.Window.Dispatcher.invoke([action]{$syncHash.Window.Close()},"Normal")
      Return
   }
  
   # This updates the control based on the parameters passed to the function
   $syncHash.$Control.Dispatcher.Invoke([action]{
      # This bit is only really meaningful for the TextBox control, which might be useful for logging progress steps
       If ($PSBoundParameters['AppendContent']) {
           $syncHash.$Control.AppendText($Value)
       } Else {
           $syncHash.$Control.$Property = $Value
       }
   }, "Normal")
}

[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
$syncHash = [hashtable]::Synchronized(@{})
$newRunspace =[runspacefactory]::CreateRunspace()
$newRunspace.ApartmentState = "STA"
$newRunspace.ThreadOptions = "ReuseThread"          
$newRunspace.Open()
$newRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)          
$psCmd = [PowerShell]::Create().AddScript({   
    [xml]$xaml = @"
    <Window
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="Window" Title="Progress..." WindowStartupLocation = "CenterScreen"
        Width = "335" Height = "130" ShowInTaskbar = "True">
        <Grid>
           <ProgressBar x:Name = "ProgressBar" Height = "20" Width = "300" HorizontalAlignment="Left" VerticalAlignment="Top" Margin = "10,10,0,0"/>
           <Label x:Name = "Label1" Height = "30" Width = "300" HorizontalAlignment="Left" VerticalAlignment="Top" Margin = "10,35,0,0"/>
           <Label x:Name = "Label2" Height = "30" Width = "300" HorizontalAlignment="Left" VerticalAlignment="Top" Margin = "10,60,0,0"/>
        </Grid>
    </Window>
"@
 
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    $syncHash.Window=[Windows.Markup.XamlReader]::Load( $reader )
    $syncHash.ProgressBar = $syncHash.Window.FindName("ProgressBar")
    $syncHash.Label1 = $syncHash.Window.FindName("Label1")
    $syncHash.Label2 = $syncHash.Window.FindName("Label2")
    $syncHash.Window.ShowDialog() | Out-Null
    $syncHash.Error = $Error
})
$psCmd.Runspace = $newRunspace
$data = $psCmd.BeginInvoke()
While (!($syncHash.Window.IsInitialized)) {
   Start-Sleep -S 1
}

} # End Begin Block


Process {

# Any long running process can be implemented here, this is just an example
$computers = Get-Content c:\temp\computers.txt
$Count = 0
Foreach ($computer in $computers) {
   $Count ++
   Update-Window Label1 Content "Pinging $computer"  
   Update-Window ProgressBar Value "$(($Count/$Computers.Count)*100)"
   If (Test-Connection $computer -Count 1 -ErrorAction SilentlyContinue) {
      Update-Window Label2 ForeGround "Green"
      Update-Window Label2 Content "$computer`: OK"
      # If using a textbox control, you might use a command like this to append to the contents of the textbox
      # Update-Window TextBox1 Text "$Computer`: OK" -AppendText
   } Else {
      Update-Window Label2 ForeGround "Red"
      Update-Window Label2 Content "$computer`: NOT OK"
   }
   Start-Sleep -S 1
}

# This closes the progress bar
Update-Window Window Close

}  # End Process Block


