<#
# https://raw.githubusercontent.com/fstudio/clangbuilder/master/WebInstaller/install.ps1 Internet Installer.
# Run PowerShell IEX 
#>
Set-StrictMode -Version latest
Import-Module -Name BitsTransfer

Function Global:Get-RegistryValue($key, $value) {
    (Get-ItemProperty $key $value).$value
}


Function Global:Create-UnCompressZip
{
param
(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a ZipFile Path")]
[ValidateNotNullorEmpty()]
 [String]$ZipSource,
[Parameter(Position=1,Mandatory=$True,HelpMessage="Enter a UnComperss Directory")]
[ValidateNotNullorEmpty()]
 [String]$Destination="$env:TEMP\UNZIP2014"
)
IF($ZipSource -eq $null)
{
 return $False
}
IF((Test-Path $ZipSource) -eq $false -and (Test-Path "${PWD}\${ZipSource}") -eq $False)
{
Write-Host -ForegroundColor  Red "PathNotFound: $ZipSource"
return $False
}
IF(!(Test-Path $Destination))
{
 New-Item -ItemType Directory -Force -Path $Destination -WarningAction SilentlyContinue
}

$ShellInterface=New-Object -com Shell.Application
$ShellInterface.namespace($Destination).copyhere($ShellInterface.namespace("$ZipSource").items())
return $True
}

Function Global:Get-DownloadFile
{
param
(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a Internet File Full Url")]
[ValidateNotNullorEmpty()]
 [String]$FileUrl,
 [String]$FileSavePath="NUL"
)
IF([System.String]::Compare($FileSavePath,"NUL") -eq 0)
{
$NposIndex=$FileUrl.LastIndexOf("/")+1
IF($NposIndex -eq $FileUrl.Length)
{
 return $Fase
}
$DownloadFd=Get-RegistryValue 'HKCU:Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders' '{374DE290-123F-4565-9164-39C4925E467B}'
$FileSigName=$FileUrl.Substring($NposIndex,$FileUrl.Length - $NposIndex)
$FileSavePath="{0}\{1}" -f $DownloadFd,$FileSigName
}
 Start-BitsTransfer $FileUrl  $FileSavePath 
}

<#
FOLDERID_Downloads
GUID	{374DE290-123F-4565-9164-39C4925E467B}	
Display Name	Downloads	
Folder Type	PERUSER	
Default Path 	%USERPROFILE%\Downloads	
CSIDL Equivalent	None	
Legacy Display Name	Not applicable	
Legacy Default Path 	Not applicable
#>

#HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders\{374DE290-123F-4565-9164-39C4925E467B}
###Default ,Your Should Input 

$Global:InstallPrefix=$null;

Function Global:Set-InstallationLocation
{
param(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter Your ClangSetup Installation Location")]
[ValidateNotNullorEmpty()]
 [String]$Prefix
 )
 $Global:InstallPrefix=$Prefix
}

IF($args.Count -lt 1)
{
Write-Host -ForegroundColor Yellow "Please Input Your ClangSetup Installation Location<your select>"
Set-InstallationLocation
}ELSE{
$Global:InstallPrefix =$args[0]
}

$DownloadInstallPackage="${env:TEMP}\ClangSetupvNextWebInstallerZIP.zip"
$OfficaUrl="https://github.com/fstudio/clangbuilder/archive/master.zip"
Get-DownloadFile -FileUrl $OfficaUrl -FileSavePath $DownloadInstallPackage
Unblock-File $DownloadInstallPackage

$IsUnZipSucc =Create-UnCompressZip -ZipSource $DownloadInstallPackage -Destination "${env:TEMP}\ClangSetupWebInstallerUnZip"
IF(!$IsUnZipSucc)
{
 Write-Host -ForegroundColor Red "Un Compress Error,Please Retry!"
 [System.Console]::ReadKey()
 return
}
 IF(!(Test-Path $Global:InstallPrefix))
 {
  Mkdir $Global:InstallPrefix
 }
 Copy-Item -Path "${Env:TEMP}\ClangSetupWebInstallerUnZip\ClangSetupvNext-master\*" "${Global:InstallPrefix}"  -Force -Recurse
 Remove-Item -Force -Recurse "$env:TEMP\ClangSetupvNextWebInstallerZIP.zip"
 Remove-Item -Force -Recurse "$env:TEMP\ClangSetupWebInstallerUnZip"

 IEX "PowerShell -NoLogo -NoExit -File ${Global:InstallPrefix}\InstallClangSetupvNext.ps1"
 Write-Host -ForegroundColor Green "Process End"
