<####################################################################################################################
#
#
#
####################################################################################################################>

IF($PSVersionTable.PSVersion.Major -lt 3)
{
Write-Host -ForegroundColor Red "ClangSetup vNext Must Run on Windows PowerShell 3 or Later,`nYour PowerShell version Is : 
${Host}"
[System.Console]::ReadKey()
Exit 1
}
Set-StrictMode -Version latest
Import-Module -Name BitsTransfer

$Global:ICSNextInvoke=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
#Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $Global:ICSNextInvoke
$Global:FastCSvN=$false
### Unzip file ,Explorer Feacture
## C:\temp\test.zip
# Shell-UnZip test.zip C:\temp C:\temp\Out
Function Global:Shell-UnZip($fileName, $sourcePath, $destinationPath)
{
    $shell = New-Object -com Shell.Application
    if (!(Test-Path "$sourcePath\$fileName"))
    {
        throw "$sourcePath\$fileName does not exist" 
    }
    New-Item -ItemType Directory -Force -Path $destinationPath -WarningAction SilentlyContinue
    $shell.namespace($destinationPath).copyhere($shell.namespace("$sourcePath\$fileName").items()) 
}

Function Global:Shell-UnzipNet45([String]$sourceFile,[String]$targetFolder)
{
[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
[System.IO.Compression.ZipFile]::ExtractToDirectory($sourceFile, $targetFolder)
}

Function Global:Get-CMakePackage()
{
$Is64BitSys=[System.Environment]::Is64BitOperatingSystem
IF($Is64BitSys -eq $True)
{
$PackageUrl="http://sourceforge.net/projects/clangonwin/files/Install/Packages/ClangSetup-Package-cmake-win64.zip/download"
}ELSE{
$PackageUrl="http://sourceforge.net/projects/clangonwin/files/Install/Packages/ClangSetup-Package-cmake-win32.zip/download"
}
#Invoke-WebRequest
Start-BitsTransfer $PackageUrl "${Global:ICSNextInvoke}\CMake.zip"
Unblock-File "${Global:ICSNextInvoke}\CMake.zip"
Write-Host -ForegroundColor Cyan "CMake Download Success"
IF((Test-Path "${Global:ICSNextInvoke}\Packages") -eq $True)
{
}ELSE{
Mkdir "${Global:ICSNextInvoke}\Packages"
}
Shell-UnZip CMake.zip $Global:ICSNextInvoke "${Global:ICSNextInvoke}\Packages\CMake"
Remove-Item -Force -Recurse "${Global:ICSNextInvoke}\CMake.zip"
}

Function Global:Get-GnuWinPackage()
{
 $GnuWinPkUrl="http://sourceforge.net/projects/clangonwin/files/Install/Packages/ClangSetup-Package-GnuWin-win32.zip/download"
 $GnuWinPkOut="${Global:ICSNextInvoke}\GunWin.zip"
 Start-BitsTransfer $GnuWinPkUrl  $GnuWinPkOut 
 Unblock-File $GnuWinPkOut
 Shell-UnZip "GunWin.zip" "$Global:ICSNextInvoke" "${Global:ICSNextInvoke}\Packages\GunWin"
 Remove-Item -Force -Recurse "${Global:ICSNextInvoke}\GunWin.zip"
}

###########Start-Process -Wait  
Function Global:Get-Python27()
{
IF([System.Environment]::Is64BitOperatingSystem -eq $True)
{
 $PythonPkUrl="https://www.python.org/ftp/python/2.7.9/python-2.7.9.amd64.msi"
}ELSE{
 $PythonPkUrl="https://www.python.org/ftp/python/2.7.9/python-2.7.9.msi"
 }
 $PythonOut="$Global:ICSNextInvoke\Python.msi"
 Start-BitsTransfer $PythonPkUrl $PythonOut
 Unblock-File $PythonOut
 Start-Process -FilePath msiexec -ArgumentList "/a `"${PythonOut}`" /qn TARGETDIR=`"${Global:ICSNextInvoke}\Packages\Python`"" -NoNewWindow -Wait
 #msiexec  /a `"${PythonOut}`" /qn TARGETDIR=`"${Global:ICSNextInvoke}\Packages\Python`""
 Write-Host -ForegroundColor Yellow "Create Package for Python,Runturn Code is : $?"
 IF($? -eq $True)
 {
   Remove-Item -Force -Recurse "${PythonOut}" 
   Remove-Item -Force -Recurse "${Global:ICSNextInvoke}\Packages\Python\Python.msi"
 }
}

Function Global:Get-Subversion()
{
IF([System.Environment]::Is64BitOperatingSystem -eq $true)
{
$SubversionPkUrl="https://sliksvn.com/pub/Slik-Subversion-1.8.13-x64.msi"
}
ELSE
{
#https://sliksvn.com/pub/Slik-Subversion-1.8.13-x64.msi
$SubversionPkUrl="https://sliksvn.com/pub/Slik-Subversion-1.8.13-win32.msi"
}
$SubversionOut="${Global:ICSNextInvoke}\Subversion.msi"
 Start-BitsTransfer $SubversionPkUrl $SubversionOut
 Unblock-File $SubversionOut
 Start-Process -FilePath msiexec -ArgumentList  "/a `"${SubversionOut}`" /qn TARGETDIR=`"${Global:ICSNextInvoke}\Packages\SVN`"" -NoNewWindow -Wait
 Write-Host -ForegroundColor Yellow "Create Package for Subversion,Return Code is : $?"
 IF($? -eq $True)
 {
 Remove-Item -Force  "${Global:ICSNextInvoke}\Packages\SVN\Subversion.msi"
 IF([System.Environment]::Is64BitOperatingSystem){
 ###64BIT
 Move-Item "${Global:ICSNextInvoke}\Packages\SVN\SlikSvn\bin\Win\System64\*"  "${Global:ICSNextInvoke}\Packages\SVN\SlikSvn\bin"
 }ELSE{
 ###32BIT
  Move-Item "${Global:ICSNextInvoke}\Packages\SVN\SlikSvn\bin\Win\System\*"  "${Global:ICSNextInvoke}\Packages\SVN\SlikSvn\bin"
 }
 Remove-Item -Force -Recurse "${Global:ICSNextInvoke}\Packages\SVN\SlikSvn\bin\Win" 
 Move-Item "${Global:ICSNextInvoke}\Packages\SVN\SlikSvn\*" "${Global:ICSNextInvoke}\Packages\SVN"
 Remove-Item -Force -Recurse "${Global:ICSNextInvoke}\Packages\SVN\SlikSvn" 
 Remove-Item -Force -Recurse ${SubversionOut}
 }
}


Function Global:Install-NSISPackage()
{
  $NSISPkUrl="http://sourceforge.net/projects/clangonwin/files/Install/Packages/ClangSetup-Package-NSIS-Win32-3.0b1.zip/download"
  $NSISPkOut="${Global:ICSNextInvoke}\NSIS.zip"
  Start-BitsTransfer $NSISPkUrl  $NSISPkOut 
  Unblock-File $NSISPkOut
  Shell-UnZip "NSIS.zip" "$Global:ICSNextInvoke" "${Global:ICSNextInvoke}\Packages\NSIS"
  Remove-Item -Force -Recurse "${Global:ICSNextInvoke}\NSIS.zip"
}


<#
Name             MemberType Definition
----             ---------- ----------
Load             Method     void Load (string)
Save             Method     void Save ()
Arguments        Property   string Arguments () {get} {set}
Description      Property   string Description () {get} {set}
FullName         Property   string FullName () {get}
Hotkey           Property   string Hotkey () {get} {set}
IconLocation     Property   string IconLocation () {get} {set}
RelativePath     Property   string RelativePath () {set}
TargetPath       Property   string TargetPath () {get} {set}
WindowStyle      Property   int WindowStyle () {get} {set}
WorkingDirectory Property   string WorkingDirectory () {get} {set}

#>

Function Global:Make-LinkEnviroment([String]$linkdir,[String]$lnkname,[String]$runfile)
{
$wshell=New-Object -ComObject WScript.Shell
$shortcut=$wshell.CreateShortcut("${linkdir}\${lnkname}.lnk")
$shortcut.TargetPath="${env:SystemRoot}\System32\WindowsPowerShell\v1.0\PowerShell.exe"
$shortcut.Description="Start ClangSetup vNext Environment"
$shortcut.WindowStyle=1
$shortcut.WorkingDirectory=$linkdir
IF($Global:FastCSvN){
$shortcut.Arguments=" -NoLogo -NoExit  -NoProfile  -File ${runfile}"
}ELSE{
$shortcut.Arguments=" -NoLogo -NoExit   -File ${runfile}"
}
$shortcut.IconLocation="${env:SystemRoot}\System32\WindowsPowerShell\v1.0\PowerShell_ise.exe,1"
$shortcut.Save()
}
####
Function Global:WriteOut-Progress([int]$prostatus)
{
Write-Host -ForegroundColor Yellow "Installation progress: ${prostatus}%`n......."
}
#################################################
#### Execute Begin
IEX -Command "${ICSNextInvoke}\bin\ClangSetupvNextUI.ps1"
Show-LauncherWindow

$status=0
Write-Host -ForegroundColor Cyan "Start Install ClangSetup vNext Environment`n"
WriteOut-Progress $status
Write-Host -ForegroundColor Cyan "Clean Packages Folder"
Remove-Item -Force -Recurse -Path "${ICSNextInvoke}\Packages\*" -Exclude PackageList.txt
$status+=5
WriteOut-Progress $status
Get-CMakePackage
$status+=10
WriteOut-Progress $status 
Get-GnuWinPackage
$status+=10
WriteOut-Progress $status 
Get-Python27
$status+=10
WriteOut-Progress $status 
Get-Subversion
$status+=10
WriteOut-Progress $status 
Install-NSISPackage
$status+=10
WriteOut-Progress $status 

Write-Host -ForegroundColor Green "CMake Subversion GnuWin NSIS Download Success.`nBegin Build Tools:"
Invoke-Expression   "${ICSNextInvoke}\tools\Install.ps1"
$status+=10
WriteOut-Progress $status 

Write-Host -ForegroundColor Yellow "`n`nBegin Make Shortcut in ${ICSNextInvoke},aways Your can click shorcut start a PowerShell Environment"
$status+=15
WriteOut-Progress $status 
Make-LinkEnviroment $ICSNextInvoke "ICSNextEnv" "${ICSNextInvoke}\ClangSetupEnvNext.ps1"


$cswshell=New-Object -ComObject WScript.Shell
$wpfshortcut=$cswshell.CreateShortcut("${ICSNextInvoke}\ClangSetupWPF.lnk")
$wpfshortcut.TargetPath="${ICSNextInvoke}\Packages\NetTools\ClangSetupvNextSet.exe"
$wpfshortcut.Description="Start ClangSetup vNext Environment"
$wpfshortcut.WindowStyle=1
$wpfshortcut.WorkingDirectory="${ICSNextInvoke}\Packages\NetTools"
$wpfshortcut.IconLocation="${ICSNextInvoke}\Packages\NetTools\ClangSetupvNextSet.exe,0"
$wpfshortcut.Save()


######
Write-Host -ForegroundColor Yellow "`n`nCheck Your Visual Studio Instanll:`n"
Invoke-Expression   "${ICSNextInvoke}\bin\VisualStudioEnvNext.ps1"
Find-VisualStudio|Out-Null
IF($Global:VS100B)
{
 Write-Host -ForegroundColor Green "Already installed Visual Studio 2010,Support X86 X64 | ClangSetup Disable Build;Enable CRT,C++STL`n"
}
IF($Global:VS110B)
{
 Write-Host -ForegroundColor Green "Already installed Visual Studio 2012,Support X86 X64 ARM | ClangSetup Enable: X86,X64 <3.6|Enable CRT,C++STL`n"
}
IF($Global:VS120B)
{
 Write-Host -ForegroundColor Green "Already installed Visual Studio 2013,Support X86 X64 ARM | ClangSetup Enable Build X86,X64;Enable CRT,C++ STL`n"
}
IF($Global:VS140B)
{
 Write-Host -ForegroundColor Green "Already installed Visual Studio 2015,Support X86 X64 ARM  | ClangSetup Enable Build X86,X64,Disable C++STL`n"
}
IF($Global:VS150B)
{
 Write-Host -ForegroundColor Green "Already installed Visual Studio 15,Support X86 X64 ARM AArch64 | ClangSetup Disable `n"
}
$status+=10
WriteOut-Progress $status 

$status=100
Get-ReadMeWindow | Out-Null


Write-Host  -ForegroundColor Green "ClangSetup vNext Installed success ,Your can Click Shortcut AutoBuilder LLVM,or user PowerShell Environment do something.
All technology is open source, please follow license agreement"

Out-ClangSetupTipsVoice "ClangSetup vNext Installed success ,Your can Click Shortcut AutoBuilder LLVM,or user PowerShell Environment do something.
All technology is open source, please follow license agreement"

[System.Console]::ReadKey()|Out-Null
