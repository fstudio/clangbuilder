#!/usr/bin/env powershell
<#############################################################################
#  PathLoaderEx.ps1
#  Note: Clangbuilder Package Installer
#  Date: 2016.09
#  Author:Force <forcemz@outlook.com>
##############################################################################>

Function Find-ExecutablePath{
    param(
        [String]$Name
    )
    if(!(Test-Path $Name)){
        return $null
    }
    $Item_=Get-ChildItem -Path "$Name\*.exe"
    if($Item_.Count -ge 1){
        $Dir=Get-Item -Path $Name
        return $Dir.FullName
    }
    $exebin="$Name\bin"
    if((Test-Path $exebin)){
        $d=Get-Item -Path $exebin
        return $d.FullName
    }
    $wapperdir="$Name\cmd"
    if((Test-Path $wapperdir)){
        $d=Get-Item -Path $wapperdir
        return $d.FullName
    }
    # self exe
}


Function Test-AddPath{
    param(
        [String]$Path
    )
    if(Test-Path $Path){
        $env:Path="$Path;${env:Path}"
    }
}

Function Test-ExecuteFile
{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter Execute Name")]
        [ValidateNotNullorEmpty()]
        [String]$ExeName
    )
    $myErr=@()
     Get-command -CommandType Application $ExeName -ErrorAction SilentlyContinue -ErrorVariable +myErr
     if($myErr.count -eq 0)
     {
         return $True
     }
     return $False
}

Function Get-RegistryValueEx{
    param(
        [ValidateNotNullorEmpty()]
        [String]$Path,
        [ValidateNotNullorEmpty()]
        [String]$Key
    )
    if(!(Test-Path $Path)){
        return 
    }
    (Get-ItemProperty $Path $Key).$Key
}

$LastCurrentDir=Get-Location
Set-Location $PSScriptRoot
$PkgCached=Get-Content -Path "$PSScriptRoot/Package.lock.json" |ConvertFrom-Json

$Members=Get-Member -InputObject $PkgCached -MemberType NoteProperty

foreach($i in $Members){
    $Dir=Find-ExecutablePath -Name $i.Name
    if($null -ne $Dir){
        Test-AddPath $Dir
    }
}

if(!(Test-ExecuteFile "git")){
    $gitkey="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
    $gitkey2="HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
    if(Test-Path $gitkey){
       $gitinstall=Get-RegistryValueEx $gitkey "InstallLocation"
       Test-AddPath "${gitinstall}\bin"
    }elseif(Test-Path $gitkey2){
        $gitinstall=Get-RegistryValueEx $gitkey2 "InstallLocation"
        Test-AddPath "${gitinstall}\bin"
    }
}

Set-Location $LastCurrentDir