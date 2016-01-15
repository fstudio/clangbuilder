<####################################################################################################################
# Clangbuilder Environment Install
# WebInstall Standalone
# Date:2016.01.03
# Author:Force <forcemz@outlook.com>
####################################################################################################################>
<#
# https://raw.githubusercontent.com/fstudio/clangbuilder/master/bin/Installer/WebInstall.ps1 Internet Installer.
# Run PowerShell IEX
#>
Set-StrictMode -Version latest
Import-Module -Name BitsTransfer

Function Global:Get-RegistryValue($key, $value) {
    (Get-ItemProperty $key $value).$value
}

Function Global:Create-UnCompressZip
{
param(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Unzip sources")]
[ValidateNotNullorEmpty()]
[String]$ZipSource,
[Parameter(Position=1,Mandatory=$True,HelpMessage="Output Directory")]
[ValidateNotNullorEmpty()]
[String]$Destination
)
if(!(Test-Path $ZipSource)){
Write-Host -ForegroundColor Red "Cannot found $ZipSource"
Exit
}
[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')|Out-Null
Write-Host "Use System.IO.Compression.ZipFile Unzip `nPackage: $ZipSource`nOutput: $Destination"
[System.IO.Compression.ZipFile]::ExtractToDirectory($ZipSource, $Destination)
}


Function Global:Get-DownloadFile
{
param
(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter a Internet File Full Url")]
[ValidateNotNullorEmpty()]
 [String]$FileUrl,
 [String]$FileSavePath
)
IF($FileSavePath -eq $null)
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

if($args.Count -lt 1)
{
Write-Host -ForegroundColor Yellow "Please Input Your Clangbuilder Installation Location<your select>"
Set-InstallationLocation
}else{
$Global:InstallPrefix =$args[0]
}

$DownloadInstallPackage="${env:TEMP}\clangbuilder.zip"
$OfficaUrl="https://github.com/fstudio/clangbuilder/archive/master.zip"
Get-DownloadFile -FileUrl $OfficaUrl -FileSavePath $DownloadInstallPackage
if(!(Test-Path $DownloadInstallPackage)){
Write-Host -ForegroundColor Red "Download $OfficaUrl Failed !"
Exit
}
Unblock-File $DownloadInstallPackage
Create-UnCompressZip -ZipSource $DownloadInstallPackage -Destination "${env:TEMP}\clangbuilder"
IF(!$(Test-Path "${env:TEMP}\clangbuilder"))
{
 Write-Host -ForegroundColor Red "Un Compress Error,Please Retry!"
 [System.Console]::ReadKey()
 return
}

 IF(!(Test-Path $Global:InstallPrefix))
 {
  Mkdir $Global:InstallPrefix
 }
 Copy-Item -Path "${Env:TEMP}\clangbuilder\clangbuilder-master\*" "${Global:InstallPrefix}"  -Force -Recurse
 Remove-Item -Force -Recurse "$env:TEMP\clangbuilder.zip"
 Remove-Item -Force -Recurse "$env:TEMP\clangbuilder"

 &PowerShell -NoLogo -NoExit -File "${Global:InstallPrefix}\bin\Installer\Install.ps1"
 
 Write-Host -ForegroundColor Green "Process done"
