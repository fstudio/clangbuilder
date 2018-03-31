# See https://blogs.msdn.microsoft.com/vcblog/2016/02/16/\
#try-out-the-latest-c-compiler-toolset-without-waiting-for-the-next-update-of-visual-studio/
."$PSScriptRoot\ProfileEnv.ps1"

$ViusalCppAtomURL = "https://visualcpp.myget.org/F/dailymsvc/api/v2"
$VisualCppToolsInstallDir = "$ClangbuilderRoot\bin\utils\msvc"

$NuGetDir = "$ClangbuilderRoot\bin\pkgs\Nuget"

$env:PATH = "$NuGetDir;${env:PATH}"

Push-Location $PWD

if (!(Test-Path $VisualCppToolsInstallDir)) {
    New-Item -Force -ItemType Directory $VisualCppToolsInstallDir 
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
    $VisualCppPackageName = $xmlfeed.feed.entry[$mindex].properties.Id
    $VisualCppToolsVersion = $xmlfeed.feed.entry[$mindex].properties.Version
}
else {
    $VisualCppPackageName = $xmlfeed.feed.entry.properties.Id
    $VisualCppToolsVersion = $xmlfeed.feed.entry.properties.Version
}

Write-Output "Latest $VisualCppPackageName version is $VisualCppToolsVersion"
if ((Test-Path "$VisualCppToolsInstallDir/VisualCppTools.lock.json")) {
    $Pkglock = Get-Content "$VisualCppToolsInstallDir/VisualCppTools.lock.json" |ConvertFrom-Json
    if ($Pkglock.Version -eq $VisualCppToolsVersion) {
        Write-Host "VisualCppTools is up to date, Version: $VisualCppToolsVersion"
        return ;
    }
}


Write-Output "NuGet Install $VisualCppPackageName $VisualCppToolsVersion ......"

&nuget install $VisualCppPackageName -Source $ViusalCppAtomURL -Prerelease

if ((Test-Path "$VisualCppToolsInstallDir\$VisualCppPackageName.$VisualCppToolsVersion")) {
    $vccache = @{}
    $vccache["Name"] = $VisualCppPackageName
    $vccache["Version"] = $VisualCppToolsVersion
    $vccache["Path"] = "$VisualCppPackageName.$VisualCppToolsVersion"
    ConvertTo-Json $vccache |Out-File -Encoding utf8 -Force -FilePath "$VisualCppToolsInstallDir\VisualCppTools.lock.json"
}

Pop-Location 
