param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch = "x64",
    [String]$InstallId,
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


if ($InstallId.Contains("11.0") -or $InstallId.Contains("10.0")) {
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



$vsinstalls = vswhere -legacy -format json|ConvertFrom-JSON
foreach ($item in $vsinstalls) {
    if ($item.instanceId -eq $InstallId) {

        $vsinstall = $item.installationPath
        $vsversion = $item.installationVersion
        Write-Host "Use: Visual Studio $vsversion"
        Write-Host "Initialize from: $vsinstall"
        if ($InstallId.StartsWith("VisualStudio")) {
            $vcvarsall = "$vsinstall\VC\vcvarsall.bat"
            if ($InstallId -eq "VisualStudio.14.0" -and $Sdklow) {
                Write-Host "Attention Please: Use Windows 8.1 SDK"
                $ArgumentList += " 8.1"
            }
        }
        else {
            $vcvarsall = "$vsinstall\VC\Auxiliary\Build\vcvarsall.bat"
            if ($Sdklow) {
                Write-Host "Attention Please: Use Windows 8.1 SDK"
                $ArgumentList += " 8.1"
            }
        }
    }
}

if (!(Test-Path $vcvarsall)) {
    Write-Host "$vcvarsall not found"
    return 1;
}


Invoke-Vcvarsall -Path $vcvarsall -ArgumentList $ArgumentList