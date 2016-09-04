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
        $d=Get-Item -Path $exebin
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

Set-Location $LastCurrentDir