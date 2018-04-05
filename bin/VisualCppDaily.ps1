# See https://blogs.msdn.microsoft.com/vcblog/2016/02/16/\
#try-out-the-latest-c-compiler-toolset-without-waiting-for-the-next-update-of-visual-studio/
."$PSScriptRoot\ProfileEnv.ps1"
$VisualCppDailyAPI = "https://visualcpp.myget.org/F/dailymsvc/api/v3/index.json"
$VisualCppDailyName = "VisualCppTools.Community.Daily.VS2017Layout"
$VisualCppToolsInstallDir = "$ClangbuilderRoot\bin\utils\msvc"
$NuGetDir = "$ClangbuilderRoot\bin\pkgs\Nuget"
$env:PATH = "$NuGetDir;${env:PATH}"
$VisualCppDailyVersion = $null
# https://visualcpp.myget.org/F/dailymsvc/api/v3/query/?q=packageid:VisualCppTools.Community.Daily.VS2017Layout&prerelease=true

try {
    $queryurl = $null
    $obj = (Invoke-WebRequest -Uri $VisualCppDailyAPI).Content |ConvertFrom-Json
    foreach ($s in $obj.resources) {
        if ($s.'@type' -eq "SearchQueryService") {
            $queryurl = $s.'@id'
        }
    }
    if ($queryurl -eq $null) {
        Write-Host -ForegroundColor Red "SearchQueryService url not found"
        exit 1
    }
    $surl = "$queryurl/?q=packageid:$VisualCppDailyName&prerelease=true"
    $vcobj = (Invoke-WebRequest -Uri $surl).Content |ConvertFrom-Json
    if ($vcobj.data -is [array]) {
        $VisualCppDailyVersion = $vcobj.data[0].version
    }
    else {
        $VisualCppDailyVersion = $vcobj.data.version
    }

}
catch {
    Write-Host -ForegroundColor Red "Check VisualCppTools Latest version error: $_"
    exit 1
}

if ($VisualCppDailyVersion -eq $null) {
    Write-Host -ForegroundColor Red "Not found valid $VisualCppDailyName version."
    exit 1
}


Push-Location $PWD

if (!(Test-Path $VisualCppToolsInstallDir)) {
    New-Item -Force -ItemType Directory $VisualCppToolsInstallDir 
}

Set-Location $VisualCppToolsInstallDir

Write-Output "Latest $VisualCppDailyName version is $VisualCppDailyVersion"
if ((Test-Path "$VisualCppToolsInstallDir/VisualCppTools.lock.json")) {
    $Pkglock = Get-Content "$VisualCppToolsInstallDir/VisualCppTools.lock.json" |ConvertFrom-Json
    if ($Pkglock.Version -eq $VisualCppDailyVersion) {
        Write-Host "VisualCppTools is up to date, Version: $VisualCppDailyVersion"
        return ;
    }
}

Write-Output "NuGet Install $VisualCppDailyName $VisualCppDailyVersion ......"
&nuget install $VisualCppDailyName -Version $VisualCppDailyVersion -Pre -Source $VisualCppDailyAPI

if ((Test-Path "$VisualCppToolsInstallDir\$VisualCppDailyName.$VisualCppDailyVersion")) {
    $vccache = @{}
    $vccache["Name"] = $VisualCppDailyName
    $vccache["Version"] = $VisualCppDailyVersion
    $vccache["Path"] = "$VisualCppDailyName.$VisualCppDailyVersion"
    ConvertTo-Json $vccache |Out-File -Encoding utf8 -Force -FilePath "$VisualCppToolsInstallDir\VisualCppTools.lock.json"
}

Pop-Location 
