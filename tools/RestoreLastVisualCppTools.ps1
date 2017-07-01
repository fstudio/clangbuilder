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
$NuGetURL="https://dist.nuget.org/win-x86-commandline/v4.1.0/nuget.exe"

Function Get-NuGetFile{
    if(!(Test-Path "$PSScriptRoot\NuGet\nuget.exe")){
        Write-Output "Download NuGet now ....."
        Invoke-WebRequest $NuGetURL -UseBasicParsing -OutFile "$PSScriptRoot\NuGet\nuget.exe"
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

Function CompareVersion(){
    param(
        [String]$Pre,
        [String]$Next
    )

}



$NugetXml=Invoke-WebRequest -UseBasicParsing -Uri "$NuGetAddSource/Packages"

$PackageMetadata=[xml]$NugetXml.Content



$VisualCppToolsVersionRaw=$PackageMetadata.feed.entry.properties.Version

if($VisualCppToolsVersionRaw.GetType().IsArray){
    Write-Host "VisualCppTools: $VisualCppToolsVersionRaw"
    $VisualCppToolsVersion=$VisualCppToolsVersionRaw[$VisualCppToolsVersionRaw.Count-1]
	$VisualCppToolsURL=$PackageMetadata.feed.entry.content.src[$VisualCppToolsVersionRaw.Count-1]
}else{
    $VisualCppToolsVersion=$VisualCppToolsVersionRaw
	$VisualCppToolsURL=$PackageMetadata.feed.entry.content.src
}

if((Test-Path "$PSScriptRoot/VisualCppTools.lock.json")){
    $Pkglock=Get-Content "$PSScriptRoot/VisualCppTools.lock.json" |ConvertFrom-Json
    if($Pkglock.VisualCppTools -eq $VisualCppToolsVersion){
        Write-Host "VisualCppTools is up to date, Version: $VisualCppToolsVersion"
        return ;
    }
}


Write-Output "NuGet Install VisualCppTools ......"
Write-Output "VisualCppTools Download URL:`n$VisualCppToolsURL $VisualCppToolsVersion"
#&nuget  install VisualCppTools -Source $NuGetAddSource -Version $VisualCppToolsPreRevision -Prerelease
#&nuget  install VisualCppTools -Source $NuGetAddSource -Prerelease
&nuget install VisualCppTools.Community.VS2017Layout -Source $NuGetAddSource -Prerelease

if((Test-Path "$PSScriptRoot/msvc/VisualCppTools.Community.VS2017Layout.$VisualCppToolsVersion")){
    $InstalledMap=@{}
    $InstalledMap["VisualCppTools"]=$VisualCppToolsVersion
    ConvertTo-Json $InstalledMap |Out-File -Force -FilePath "$PSScriptRoot\VisualCppTools.lock.json"
}

Pop-Location 
