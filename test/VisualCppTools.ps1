#!/usr/bin/env powershell

$ClangbuilderDir = Split-Path $PSScriptRoot
$VisualCppAtomURL = "http://vcppdogfooding.azurewebsites.net/nuget/"
$VisualCppInstallDir = "$ClangbuilderDir/utils/msvc"

$VisualCppName = $null
$VisualCppVersion = $null
$VisualCppUri = $null
$VisualCppXmlElement = $null

try {
    $VisualCppXmlElement = [xml](Invoke-WebRequest -UseBasicParsing -Uri "$VisualCppAtomURL/Packages").Content
}
catch {
    Write-Host -ForegroundColor Red "Check $_"
    exit 1
}

if ($VisualCppXmlElement.feed.entry.GetType().IsArray) {
    [int]$index = 0;
    [int]$mindex = 0;
    [int]$build = 1;
    foreach ($_ in $VisualCppXmlElement.feed.entry) {
        $version = $_.properties.Version.Split("-")[0]; # 14.11.25615-Pre
        $ver = [System.Version]::Parse($version)
        if ($ver.build -gt $build) {
            $build = $ver.build
            $mindex = $index
        }
        $index++
    }
    $VisualCppName = $VisualCppXmlElement.feed.entry[$mindex].title.'#text'
    $VisualCppVersion = $VisualCppXmlElement.feed.entry[$mindex].properties.Version
    $VisualCppUri = $VisualCppXmlElement.feed.entry[$mindex].content.src
}
else {
    $VisualCppName = $VisualCppXmlElement.feed.entry.title.'#text'
    $VisualCppVersion = $VisualCppXmlElement.feed.entry.properties.Version
    $VisualCppUri = $VisualCppXmlElement.feed.entry.content.src
}

Write-Host "Download $VisualCppName[$VisualCppVersion]: $VisualCppUri"

if (!(Test-Path $VisualCppInstallDir)) {
    try {
        New-Item -Force -Path $VisualCppInstallDir -ItemType Directory |Out-Null
    }
    catch {
        Write-Host -ForegroundColor Red "mkdir $VisualCppInstallDir error $_"
        exit 1
    }
}

Push-Location $PWD
Set-Location $VisualCppInstallDir

try {
    Invoke-WebRequest -Uri $VisualCppUri -OutFile "$VisualCppInstallDir/$VisualCppVersion.zip"
}
catch {
    Write-Host -ForegroundColor Red "$_"
    exit 1
}

Expand-Archive -Path "$VisualCppInstallDir/$VisualCppVersion.zip" -DestinationPath "$VisualCppInstallDir/$VisualCppName.$VisualCppVersion"