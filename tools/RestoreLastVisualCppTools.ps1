<##########################################################################################
# Install VisualCppTools Prerelease
# Author: Force Charlie
# Date: 2016.02
# Copyright (C) 2016 Force Charlie. All Rights Reserved.
###########################################################################################>


# See https://blogs.msdn.microsoft.com/vcblog/2016/02/16/try-out-the-latest-c-compiler-toolset-without-waiting-for-the-next-update-of-visual-studio/
# nuget install VisualCppTools -source http://vcppdogfooding.azurewebsites.net/nuget/ -Prerelease

Push-Location $PWD
#XML sources: http://vcppdogfooding.azurewebsites.net/nuget/Packages
#$NuGetUserConfig="$env:AppData\NuGet\NuGet.config"
$NuGetAddSource="http://vcppdogfooding.azurewebsites.net/nuget/"
$VisualCppToolsInstallDir="$PSScriptRoot\msvc"
$NugetToolsDir="$PSScriptRoot\Nuget"
$NuGetURL="https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"

Function Get-NuGetFile{
    if(!(Test-Path "$PSScriptRoot\NuGet\nuget.exe")){
        Write-Output "Download NuGet now ....."
        Invoke-WebRequest $NuGetURL -OutFile "$PSScriptRoot\NuGet\nuget.exe"
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

if(!(Test-ExecuteFile "nuget")){
    $env:PATH=$env:PATH+";"+$NugetToolsDir
}

if(!(Test-ExecuteFile "nuget")){
    Get-NuGetFile
}


if(!(Test-Path $VisualCppToolsInstallDir)){
    mkdir -Force $VisualCppToolsInstallDir
}

Set-Location $VisualCppToolsInstallDir


$NugetXml=Invoke-WebRequest -Uri "$NuGetAddSource/Packages"

$PackageMetadata=[xml]$NugetXml.Content

$VisualCppToolsURL=$PackageMetadata.feed.entry.content.src

$VisualCppToolsVersion=$PackageMetadata.feed.entry.properties.Version

if((Test-Path "$PSScriptRoot/VisualCppTools.lock.json")){
    $Pkglock=Get-Content "$PSScriptRoot/VisualCppTools.lock.json" |ConvertFrom-Json
    if($Pkglock.VisualCppTools -eq $VisualCppToolsVersion){
        Write-Host "VisualCppTools is up to date, Version: $VisualCppToolsVersion"
        return ;
    }
}


Write-Output "NuGet Install VisualCppTools ......"
Write-Output "VisualCppTools Download URL:`n$VisualCppToolsURL"
#&nuget  install VisualCppTools -Source $NuGetAddSource -Version $VisualCppToolsPreRevision -Prerelease
&nuget  install VisualCppTools -Source $NuGetAddSource  -Prerelease

if((Test-Path "$PSScriptRoot/msvc/VisualCppTools.$VisualCppToolsVersion")){
    $InstalledMap=@{}
    $InstalledMap["VisualCppTools"]=$VisualCppToolsVersion
    ConvertTo-Json $InstalledMap |Out-File -Force -FilePath "$PSScriptRoot\VisualCppTools.lock.json"
}

Pop-Location 
