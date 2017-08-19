# to loading visualcpptools environment
param(
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch = "x64",
    [Switch]$Sdklow
)

# Host Env
$IsWindows64 = [System.Environment]::Is64BitOperatingSystem
if ($IsWindows64) {
    $Global:HostEnv = "x64"
}
else {
    $Global:HostEnv = "x86"
}


Function InitializeVS2017Layout {
    param(
        [String]$Path,
        [String]$Arch
    )
    $env:INCLUDE = "$env:INCLUDE;$Path\include;$Path\atlmfc\include;"
    if ($Global:HostEnv -eq $Arch) {
        $env:PATH = "$env:PATH;$Path\bin\Host$Arch\$Arch"
    }
    else {
        $env:PATH = "$env:PATH;$Path\bin\Host$Global:HostEnv\$Arch;$Path\bin\Host$Global:HostEnv\$Global:HostEnv"
    }
    $env:LIB = "$env:LIB;$Path\lib\$Arch"
}

Function InitializeVS14Layout {
    param(
        [String]$Path,
        [String]$Arch
    )
    $env:INCLUDE = "$env:INCLUDE;$Path\include;$Path\atlmfc\include;"
    switch ($Arch) {
        "x64" {
            $env:LIB = "$env:LIB;$Path\lib\amd64"
            if ($Global:HostEnv -eq "x64") {
                $env:PATH = "$env:PATH;$Path\bin\amd64"
            }
            else {
                $env:PATH = "$env:PATH;$Path\bin\x86_amd64;$Path\bin"
            }
        }
        "x86" {
            $env:LIB = "$env:LIB;$Path\lib"
            if ($Global:HostEnv -eq "x64") {
                $env:PATH = "$env:PATH;$Path\bin\amd64_x86;$Path\bin\amd64"
            }
            else {
                $env:PATH = "$env:PATH;$Path\bin"
            }
        }
        "arm" {
            if ($Global:HostEnv -eq "x64") {
                $env:PATH = "$env:PATH;$Path\bin\amd64_arm;$Path\bin\amd64"
            }
            else {
                $env:PATH = "$env:PATH;$Path\bin;$Path\bin\x86_arm"
            }
            $env:LIB = "$env:LIB;$Path\lib\arm"
        }
        "arm64" {
            if ($Global:HostEnv -eq "x64") {
                $env:PATH = "$env:PATH;$Path\bin\amd64_arm64;$Path\bin\amd64"
            }
            else {
                $env:PATH = "$env:PATH;$Path\bin;$Path\bin\x86_arm64"
            }
            $env:LIB = "$env:LIB;$Path\lib\arm64"
        }
        Default {}
    }

}


#\Microsoft\Microsoft SDKs\Windows\v10.0
Function InitializeWinSdk10 {
    param(
        [String]$Arch
    )
    # Windows Kits\Installed Roots\ 
    $sdk10 = "HKLM:SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0"
    if (!(Test-Path $sdk10)) {
        $sdk10 = "HKLM:SOFTWARE\Microsoft\Microsoft SDKs\Windows\v10.0"
    }
    $pt = Get-ItemProperty -Path $sdk10
    $version = "$($pt.ProductVersion).0"
    $installdir = $pt.InstallationFolder
    $env:LIB = "$env:LIB;${installdir}lib\$version\um\$Arch;${installdir}lib\$version\ucrt\$Arch"
    $env:INCLUDE += ";${installdir}include\$version\shared;"
    $env:INCLUDE += "${installdir}include\$version\ucrt;"
    $env:INCLUDE += "${installdir}include\$version\um;"
    $env:INCLUDE += "${installdir}include\$version\winrt"
    $env:PATH = "$env:PATH;${installdir}bin\$version\$Global:HostEnv"
}

Function InitailizeWinSdk81 {
    param(
        [String]$Arch
    )
    $sdk81 = "HKLM:SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v8.1"
    if (!(Test-Path $sdk81)) {
        $sdk81 = "HKLM:SOFTWARE\Microsoft\Microsoft SDKs\Windows\v8.1"
    }
    $pt = Get-ItemProperty -Path $sdk81
    $installdir = $pt.InstallationFolder
    $env:LIB = "$env:LIB;${installdir}lib\winv6.3\um\$Arch"
    $env:INCLUDE += ";${installdir}include\shared;"
    $env:INCLUDE += "${installdir}include\um;"
    $env:INCLUDE += "${installdir}include\winrt"
    $env:PATH = "$env:PATH;${installdir}bin\$Global:HostEnv"
}

$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot
$VisualCppToolsInstallDir = "$ClangbuilderRoot\utils\msvc"
$LockFile = "$VisualCppToolsInstallDir\VisualCppTools.lock.json"

if (!(Test-Path $LockFile)) {
    Write-Host -ForegroundColor Red "Not Found VisualCppTools.Community.Daily
    Please run '$ClangbuilderRoot\script\VisualCppToolsFetch.bat'"
    exit 1
}


$instlock = Get-Content -Path $LockFile |ConvertFrom-Json

if ($Sdklow) {
    InitailizeWinSdk81 -Arch $Arch
}
else {
    InitializeWinSdk10  -Arch $Arch
}

$tooldir = "$ClangbuilderRoot\utils\msvc\$($instlock.Path)\lib\native"

if ($instlock.Name.Contains("VS2017Layout")) {
    InitializeVS2017Layout -Path $tooldir -Arch $Arch
}
else {
    InitializeVS14Layout -Path $tooldir -Arch $Arch
}
