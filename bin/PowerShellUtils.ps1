

Function Get-SystemInfo
{
  param($ComputerName = $env:COMPUTERNAME)

  $header = 'Hostname','OSName','OSVersion','OSManufacturer','OSConfiguration','OS Build Type','RegisteredOwner','RegisteredOrganization','Product ID','Original Install Date','System Boot Time','System Manufacturer','System Model','System Type','Processor(s)','BIOS Version','Windows Directory','System Directory','Boot Device','System Locale','Input Locale','Time Zone','Total Physical Memory','Available Physical Memory','Virtual Memory: Max Size','Virtual Memory: Available','Virtual Memory: In Use','Page File Location(s)','Domain','Logon Server','Hotfix(s)','Network Card(s)'

  systeminfo.exe /FO CSV /S $ComputerName |
    Select-Object -Skip 1 | 
    ConvertFrom-CSV -Header $header 
}
 
function Get-WirelessAdapter
{
  Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Network\*\*\Connection' -ErrorAction SilentlyContinue |
    Select-Object -Property MediaSubType, PNPInstanceID |
    Where-Object { $_.MediaSubType -eq 2 -and $_.PnpInstanceID } |
    Select-Object -ExpandProperty PnpInstanceID |
    ForEach-Object {
      $wmipnpID = $_.Replace('\', '\\')
      Get-WmiObject -Class Win32_NetworkAdapter -Filter "PNPDeviceID='$wmipnpID'"
    } 
} 

Function Global:Set-ProcessLowLevel
{
$process = Get-Process -Id $pid
$process.PriorityClass = 'BelowNormal'
}
