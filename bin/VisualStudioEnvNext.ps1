<####################################################################################################################
# Visual Studio Environment vNext
# Note: Auto Search Visual Studio Install.and Configuration VisualStudio Environment.
#>

<####################################################################################################################
#System Check, delete it
# --->Windows PowerShell 3.0 Run on Windows 7 or Windows 8,
IF($PSVersionTable.BuildVersion.Build -lt 7601)
{
Write-Host -ForegroundColor Red "Visual Studio Environment Must Run on Windows 7SP1 or Later."
[System.Console]::ReadKey()
Exit 2
}
####################################################################################################################>

<####################################################################################################################
Register Key:

Native    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSBuild\ToolsVersions\12.0\MSBuildToolsPath
WOW64 HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\MSBuild\ToolsVersions\12.0\MSBuildToolsPath


####################################################################################################################>


IF($PSVersionTable.PSVersion.Major -lt 3)
{
Write-Host -ForegroundColor Red "Visual Studio Enviroment vNext Must Run on Windows PowerShell 3 or Later,`nYour PowerShell version Is : 
${Host}"
[System.Console]::ReadKey()
return 
}

$Global:VSENINFO="VisualStudio Environment vNext"
$Global:MARJORREV=1
$Global:MINORREV=0
$Global:BUILDREV=0
$Global:REVISION=5

Function Global:Get-RegistryValue($key, $value) { 
                  (Get-ItemProperty $key $value).$value 
}

## Visual Studio Tools Status
$Global:VS100B=$false
$Global:VS110B=$false
$Global:VS120B=$false
$Global:VS140B=$false
$Global:VS150B=$false
$Global:VS160B=$false
$Global:VS170B=$false


Function Global:Find-VisualStudio()
{
IF($env:VS100COMNTOOLS -ne $null -and (Test-Path $env:VS100COMNTOOLS))
  {
   $Global:VS100B=$True;
  }
IF($env:VS100COMNTOOLS -ne $null -and (Test-Path $env:VS110COMNTOOLS))
  {
   $Global:VS110B=$True;
  }
IF($env:VS120COMNTOOLS -ne $null -and (Test-Path $env:VS120COMNTOOLS))
  {
   $Global:VS120B=$True;
  }
 IF($env:VS140COMNTOOLS -ne $null -and (Test-Path $env:VS140COMNTOOLS))
  {
   $Global:VS140B=$True;
  }
 IF($env:VS150COMNTOOLS -ne $null -and (Test-Path $env:VS150COMNTOOLS))
  {
   $Global:VS150B=$True;
  }
 IF($env:VS160COMNTOOLS -ne $null -and (Test-Path $env:VS160COMNTOOLS))
  {
   $Global:VS160B=$True;
  }
}


Function Global:Print-Help()
{
Write-Host -ForegroundColor Magenta "Visual Studio Enviroment vNext Revision: ${MARJORREV}.${MINORREV}"
Write-Host -ForegroundColor Cyan "Usage:`nInvoke-Expression -Command VisualStudioEnvNext.ps1 VSver Target 
VSver:`nVS100 VS110 VS120 VS140(CTP) VS150(Long Time Next)
Target:`nX86 X64 ARM AArch64`n
Support Matrix:
VS100      [Visual Studio 2010] Enable-Target: X86 X64
VS110      [Visual Studio 2012] Enable-Target: X86 X64 ARM
VS120      [Visual Studio 2013] Enable-Target: X86 X64 ARM
VS140      [Visual Studio 2015] Enable-Target: X86 X64 ARM
VS150      [Visual Studio 201x] Enable-Target: X86 X64 ARM AArch64 <Forecast>`n
Other Options:
-v         Print VisualStudio Environment Version
-h         Print Help and Usage
-f         Find the already installed version of VisualStudio
"
Write-Host -ForegroundColor Cyan "Copyright $([Char]0xA9) 2014 ForceStudio All Rights Reserved."
}

Function Global:Print-Version()
{
Write-Host -ForegroundColor Green "VisualStudio Environment vNext`nMajor Minor Build Revision
----- ----- ----- --------
${MARJORREV}     ${MINORREV}     ${BUILDREV}     ${REVISION}`n"
Write-Host -ForegroundColor Cyan "Copyright $([Char]0xA9) 2014 ForceStudio All Rights Reserved.`n"
}


Function Global:Print-VisualStudioNotFound([String]$VSVer,[String]$VSPATH)
{
  Print-Help
  Write-Host -ForegroundColor Red "Can not find $VSVer, Please seized car in this directory(${VSPATH}) VisualStudio version and installation"
  [System.Console]::ReadKey()
  return 
}

Function  Global:Check-TargetIsEnable([String]$VSVerStr,[String]$TargetStr)
{
  $VSVerList=@("VS100","VS110","VS120","VS140","VS150")
  foreach($VScurver in $VSVerList)
  {
   [System.System]::Compare($VSVerStr,$VScurver,$True)
  }
}

#HKEY_LOCAL_MACHINE\HARDWARE\RESOURCEMAP\Hardware Abstraction Layer\ACPI x64 platform
# HKLM:\HARDWARE\RESOURCEMAP\Hardware Abstraction Layer\ACPI x64 platform
IF([System.Environment]::Is64BitOperatingSystem -eq $True)
{
$HostArch=6401
#$HostArch
}ELSEIF([System.String]::Compare($env:PROCESSOR_ARCHITECTURE,"ARM",$True) -eq 0)
{
$HostArch=3202
}ELSE
{
  $HostArch=3201
}

IF($args.Count -ge 2)
{
$VSMark=$args[0].ToString().ToUpper()
$Target=$args[1].ToString().ToUpper()
}ELSEIF($args.Count -eq 1){
IF([System.String]::Compare($args[0],"-h",$True) -eq 0)
{
  Print-Help
  return 
}
IF([System.String]::Compare($args[0], "-v",$True) -eq 0)
{
 Print-Version
 return 
}
IF([System.String]::Compare($args[0],"-f",$True) -eq 0)
{
 Find-VisualStudio
 return 
}
}ELSE{
Print-Help
Write-Host -ForegroundColor Red "Your Should Type Parameters"
return
}

<#
Compiler MSBuild SDK .NET
Include PATH LIB Referce 
Compiler IDE Windows SDK Kit PATH
Compiler First MSbuild Second,Kit ,or other ,IDE 
x64 Check Is Support AMD64 Native Compiler,else x86_64
x86 x86 Tools
ARM x86 or x64 
#>

$VSESDK="8.0"
$Fmk="4.5"
$VSMajor="12.0"
$VSVersion="VS110"
$Platform="X86"

IF($args.Count -ge 1)
{
IF([System.String]::Compare($args[0],"VS100") -eq 0)
{
  $VSMajor="10.0"
}
ELSEIF([System.String]::Compare($args[0],"VS110") -eq 0)
{
  $VSMajor="11.0"
}
ELSEIF([System.String]::Compare($args[0],"VS120") -eq 0)
{
  $VSMajor="12.0"
}
ELSEIF([System.String]::Compare($args[0],"VS140") -eq 0)
{
  $VSMajor="14.0"
}
ELSEIF([System.String]::Compare($args[0],"VS150") -eq 0)
{
  $VSMajor="15.0"
}
}
IF($args.Count -ge 2)
{
IF([System.String]::Compare($args[1],"X86") -eq 0)
{
  $Platform="X86"
}
IF([System.String]::Compare($args[1],"X64") -eq 0)
{
  $Platform="X64"
}
ELSEIF([System.String]::Compare($args[1],"ARM") -eq 0)
{
  $Platform="ARM"
}
ELSEIF([System.String]::Compare($args[1],"AArch64") -eq 0)
{
  $Platform="AArch64"
}
}




IF([System.String]::Compare($VSVersion,"VS100") -eq  0)
{
 IF((!Test-Path $env:VS100COMNTOOLS))
 {
  Print-VisualStudioNotFound "Visual Studio 2010 " $env:VS100COMNTOOLS
  return
 }ELSE{

 }
}