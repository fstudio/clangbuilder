param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch = "x64",
    [String]$InstanceId,
    [Switch]$Sdklow = $false
)

Function Invoke-Vcvarsall {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [string] $ArgumentList
    )
    Set-StrictMode -Version Latest
    $tempFile = [IO.Path]::GetTempFileName()
    cmd /c " `"$Path`" $argumentList && set > `"$tempFile`" "
    ## Go through the environment variables in the temp file.
    ## For each of them, set the variable in our local environment.
    Get-Content $tempFile | Foreach-Object {
        if ($_ -match "^(.*?)=(.*)$") {
            Set-Content "env:\$($matches[1])" $matches[2]
        }
    }
    Remove-Item $tempFile
}

$IsWindows64 = [System.Environment]::Is64BitOperatingSystem


if ($InstanceId.Contains("11.0") -or $InstanceId.Contains("10.0")) {
    $ArchListX86 = @{
        "x86"   = "x86";
        "x64"   = "x86_amd64";
        "ARM"   = "x86_arm";
        "ARM64" = "unknwon"
    }

    $ArchListX64 = @{
        "x86"   = "x86";
        "x64"   = "amd64";
        "ARM"   = "x86_arm";
        "ARM64" = "unknwon"
    }
}
else {
    $ArchListX86 = @{
        "x86"   = "x86";
        "x64"   = "x86_amd64";
        "ARM"   = "x86_arm";
        "ARM64" = "x86_arm64"
    }

    $ArchListX64 = @{
        "x86"   = "amd64_x86";
        "x64"   = "amd64";
        "ARM"   = "amd64_arm";
        "ARM64" = "amd64_arm64"
    }
}


if ($IsWindows64) {
    $ArgumentList = $ArchListX64[$Arch]
}
else {
    $ArgumentList = $ArchListX86[$Arch]
}


## Always JSON Array

$vsinstances = vswhere -prerelease -legacy -format json|ConvertFrom-JSON
$vsinstance = $vsinstances|Where-Object {$_.instanceId -eq $InstanceId}

Write-Host "Use Visual Studio $($vsinstance.installationVersion)"

if ($vsinstance.instanceId.StartsWith("VisualStudio")) {
    $vcvarsall = "$($vsinstance.installationPath)\VC\vcvarsall.bat"
    if ($InstallId -eq "VisualStudio.14.0" -and $Sdklow) {
        Write-Host "Attention Please: Use Windows 8.1 SDK"
        $ArgumentList += " 8.1"
    }
    if (!(Test-Path $vcvarsall)) {
        Write-Host "$vcvarsall not found"
        return 1;
    }
    Invoke-Vcvarsall -Path $vcvarsall -ArgumentList $ArgumentList
    return 
}


## Now 15.4.26823.1 support Visual C++ for ARM64
$FixedVer = [System.Version]::Parse("15.4.26823.0")
$ver = [System.Version]::Parse($vsinstance.installationVersion)
$vercmp = $ver.CompareTo($FixedVer)
if ($Arch -eq "ARM64" -and $vercmp -le 0) {
    Write-Host "Use Enterprise WDK support ARM64"
    Invoke-Expression "$PSScriptRoot\EnterpriseWDK.ps1"
    return ;
}
$vcvarsall = "$($vsinstance.installationPath)\VC\Auxiliary\Build\vcvarsall.bat"

$env:VS150COMNTOOLS="$($vsinstance.installationPath)\Common7\Tools\"

if ($Sdklow) {
    Write-Host "Attention Please: Use Windows 8.1 SDK"
    $ArgumentList += " 8.1"
}

if (!(Test-Path $vcvarsall)) {
    Write-Host "$vcvarsall not found"
    return 1;
}


Invoke-Vcvarsall -Path $vcvarsall -ArgumentList $ArgumentList