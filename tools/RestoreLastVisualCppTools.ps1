<##########################################################################################
# Install VisualCppTools Prerelease
# Author: Force Charlie
# Date: 2016.02
# Copyright (C) 2016 Force Charlie. All Rights Reserved.
###########################################################################################>


# See https://blogs.msdn.microsoft.com/vcblog/2016/02/16/\
#try-out-the-latest-c-compiler-toolset-without-waiting-for-the-next-update-of-visual-studio/

Push-Location $PWD

$ViusalCppAtomURL = "http://vcppdogfooding.azurewebsites.net/nuget/"
$VisualCppToolsInstallDir = "$PSScriptRoot\msvc"
$ClangbuilderDir = Split-Path $PSScriptRoot
$NuGetDir = "$ClangbuilderDir\pkgs\Nuget"

$env:PATH = "$NuGetDir;${env:PATH}"

if (!(Test-Path $VisualCppToolsInstallDir)) {
    mkdir -Force $VisualCppToolsInstallDir
}

Set-Location $VisualCppToolsInstallDir

Function CompareVersion() {
    param(
        [String]$Pre,
        [String]$Next
    )

}

$xmlfeed = $null
try {
    $xmlfeed = [xml](Invoke-WebRequest -UseBasicParsing -Uri "$ViusalCppAtomURL/Packages").Content
}
catch {
    Write-Host -Forceground Red "Checking VisualCpp Feed $_"
    exit 1
}


$VisualCppPackageName = $null
$VisualCppToolsVersion = $null

if ($xmlfeed.feed.entry.GetType().IsArray) {
    [int]$index = 0;
    [int]$mindex = 0;
    [int]$build = 1;
    foreach ($_ in $xmlfeed.feed.entry) {
        $version = $_.properties.Version.Split("-")[0]; # 14.11.25615-Pre
        $ver = [System.Version]::Parse($version)
        if ($ver.build -gt $build) {
            $build = $ver.build
            $mindex = $index
        }
        $index++
    }
    $VisualCppPackageName = $xmlfeed.feed.entry[$mindex].title.'#text'
    $VisualCppToolsVersion = $xmlfeed.feed.entry[$mindex].properties.Version
}
else {
    $VisualCppPackageName = $xmlfeed.feed.entry.title.'#text'
    $VisualCppToolsVersion = $xmlfeed.feed.entry.properties.Version
}

Write-Output "Latest $VisualCppPackageName version is $VisualCppToolsVersion"
if ((Test-Path "$PSScriptRoot/VisualCppTools.lock.json")) {
    $Pkglock = Get-Content "$PSScriptRoot/VisualCppTools.lock.json" |ConvertFrom-Json
    if ($Pkglock.VisualCppTools -eq $VisualCppToolsVersion) {
        Write-Host "VisualCppTools is up to date, Version: $VisualCppToolsVersion"
        return ;
    }
}


Write-Output "NuGet Install $VisualCppPackageName $VisualCppToolsVersion ......"

&nuget install $VisualCppPackageName -Source $ViusalCppAtomURL -Prerelease

if ((Test-Path "$PSScriptRoot/msvc/$VisualCppPackageName.$VisualCppToolsVersion")) {
    $InstalledMap = @{}
    $InstalledMap["VisualCppTools"] = $VisualCppToolsVersion
    ConvertTo-Json $InstalledMap |Out-File -Encoding utf8 -Force -FilePath "$PSScriptRoot\VisualCppTools.lock.json"
}

Pop-Location 
