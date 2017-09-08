# VisualStudio Modules

Function Invoke-BatchFile {
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


Function Get-ArchBatchString {
    param(
        [String]$InstanceId,
        [String]$Arch
    )
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
    
    if ([System.Environment]::Is64BitOperatingSystem) {
        return $ArchListX64[$Arch]
    }
    else {
        return $ArchListX86[$Arch]
    }
}


Function EnterpriseWDK {
    param(
        [String]$ClangbuilderRoot
    )
    $EWDKFile = "$ClangbuilderRoot\config\ewdk.json"
    if (!(Test-Path $EWDKFile)) {
        Write-Error "Not Enterprise WDK config file"
        return 1
    }
    $EWDKObj = Get-Content -Path "$EWDKFile" |ConvertFrom-Json
    $EWDKPath = $EWDKObj.Path
    $EWDKVersion = $EWDKObj.Version
    if (!(Test-Path $EWDKPath)) {
        Write-Error "Not Enterprise WDK directory !"
        return 1
    }
    
    Write-Host "Initialize Windows 10 Enterprise WDK ARM Environment ..."
    Write-Host "Enterprise WDK Version: $EWDKVersion"
    
    $BuildTools = "$EWDKPath\Program Files\Microsoft Visual Studio\2017\BuildTools"
    $SDKKIT = "$EWDKPath\Program Files\Windows Kits\10"
    $VCToolsVersion = (Get-Content "$BuildTools\VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.txt").Trim()
    
    Write-Host "Visual C++ Version: $VCToolsVersion"
    
    # Configuration Include Path
    $env:INCLUDE = "$BuildTools\VC\Tools\MSVC\$VCToolsVersion\include;$BuildTools\VC\Tools\MSVC\$VCToolsVersion\atlmfc\include;"
    $includedirs = Get-ChildItem -Path "$SDKKIT\include\$EWDKVersion" | Foreach-Object {$_.FullName}
    foreach ($_i in $includedirs) {
        $env:INCLUDE = "$env:INCLUDE;$_i"
    }
    
    if ([System.Environment]::Is64BitOperatingSystem) {
        $HostEnv = "x64"
    }
    else {
        $HostEnv = "x86"
    }
    
    $env:PATH += "$SDKKIT\bin\$EWDKVersion\$HostEnv;$BuildTools\VC\Tools\MSVC\$VCToolsVersion\bin\Host$HostEnv\arm64\;"
    $env:PATH += "$BuildTools\VC\Tools\MSVC\$VCToolsVersion\onecore\$HostEnv\Microsoft.VC150.CRT\;$SDKKIT\Redist\ucrt\DLLs\$HostEnv"
    $env:PATH += "$EWDKFile\Program Files\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.7.1 Tools;$BuildTools\MSBuild\15.0\Bin"
    $env:LIB = "$BuildTools\VC\Tools\MSVC\$VCToolsVersion\lib\arm64;$BuildTools\VC\Tools\MSVC\$VCToolsVersion\atlmfc\lib\arm64;"
    $env:LIB += "$SDKKIT\lib\$EWDKVersion\km\arm64;$SDKKIT\lib\$EWDKVersion\um\arm64;$SDKKIT\lib\$EWDKVersion\ucrt\arm64;"
    $env:LIBPATH = "$BuildTools\VC\Tools\MSVC\$VCToolsVersion\lib\arm64;$BuildTools\VC\Tools\MSVC\$VCToolsVersion\atlmfc\lib\arm64;"
    $env:LIBPATH = "$SDKKIT\UnionMetadata\$EWDKVersion\;$SDKKIT\References\$EWDKVersion\;"
}


Function InitializeVS2017Layout {
    param(
        [String]$Path,
        [String]$Arch,
        [String]$HostEnv="x64"
    )
    $env:INCLUDE = "$env:INCLUDE;$Path\include;$Path\atlmfc\include;"
    if ($HostEnv -eq $Arch) {
        $env:PATH = "$env:PATH;$Path\bin\Host$Arch\$Arch"
    }
    else {
        $env:PATH = "$env:PATH;$Path\bin\Host$HostEnv\$Arch;$Path\bin\Host$HostEnv\$HostEnv"
    }
    $env:LIB = "$env:LIB;$Path\lib\$Arch"
}

Function InitializeVS14Layout {
    param(
        [String]$Path,
        [String]$Arch,
        [String]$HostEnv
    )
    $env:INCLUDE = "$env:INCLUDE;$Path\include;$Path\atlmfc\include;"
    switch ($Arch) {
        "x64" {
            $env:LIB = "$env:LIB;$Path\lib\amd64"
            if ($HostEnv -eq "x64") {
                $env:PATH = "$env:PATH;$Path\bin\amd64"
            }
            else {
                $env:PATH = "$env:PATH;$Path\bin\x86_amd64;$Path\bin"
            }
        }
        "x86" {
            $env:LIB = "$env:LIB;$Path\lib"
            if ($HostEnv -eq "x64") {
                $env:PATH = "$env:PATH;$Path\bin\amd64_x86;$Path\bin\amd64"
            }
            else {
                $env:PATH = "$env:PATH;$Path\bin"
            }
        }
        "arm" {
            if ($HostEnv -eq "x64") {
                $env:PATH = "$env:PATH;$Path\bin\amd64_arm;$Path\bin\amd64"
            }
            else {
                $env:PATH = "$env:PATH;$Path\bin;$Path\bin\x86_arm"
            }
            $env:LIB = "$env:LIB;$Path\lib\arm"
        }
        "arm64" {
            if ($HostEnv -eq "x64") {
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
        [String]$Arch,
        [String]$HostEnv="x64"
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
    $env:PATH = "$env:PATH;${installdir}bin\$version\$HostEnv"
}

Function InitializeUCRT{
    param(
        [String]$Arch,
        [String]$HostEnv="x64"
    )
    $sdk10 = "HKLM:SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0"
    if (!(Test-Path $sdk10)) {
        $sdk10 = "HKLM:SOFTWARE\Microsoft\Microsoft SDKs\Windows\v10.0"
    }
    $pt = Get-ItemProperty -Path $sdk10
    $version = "$($pt.ProductVersion).0"
    $installdir = $pt.InstallationFolder
    $env:INCLUDE += ";${installdir}include\$version\ucrt"
    $env:LIB = "$env:LIB;${installdir}lib\$version\ucrt\$Arch"
}

Function InitailizeWinSdk81 {
    param(
        [String]$Arch,
        [String]$HostEnv
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
    $env:PATH = "$env:PATH;${installdir}bin\$HostEnv"
    InitializeUCRT -Arch $Arch -HostEnv $HostEnv
}

Function InitializeVisualCppTools{
    param(
        [String]$ClangbuilderRoot,
        [ValidateSet("x86", "x64", "ARM", "ARM64")]
        [String]$Arch = "x64",
        [String]$InstanceId,
        [Switch]$Sdklow
    )
    $VisualCppToolsInstallDir = "$ClangbuilderRoot\utils\msvc"
    $LockFile = "$VisualCppToolsInstallDir\VisualCppTools.lock.json"
    
    if (!(Test-Path $LockFile)) {
        Write-Host -ForegroundColor Red "Not Found VisualCppTools.Community.Daily
        Please run '$ClangbuilderRoot\script\VisualCppToolsFetch.bat'"
        return 1
    }
    
    
    $instlock = Get-Content -Path $LockFile |ConvertFrom-Json
    $HostEnv="x86"
    if([System.Environment]::Is64BitOperatingSystem){
        $HostEnv="x64"
    }
    if ($Sdklow) {
        InitailizeWinSdk81 -Arch $Arch -HostEnv $HostEnv
    }
    else {
        InitializeWinSdk10  -Arch $Arch -HostEnv $HostEnv
    }
    
    $tooldir = "$ClangbuilderRoot\utils\msvc\$($instlock.Path)\lib\native"
    
    if ($instlock.Name.Contains("VS2017Layout")) {
        InitializeVS2017Layout -Path $tooldir -Arch $Arch -HostEnv $HostEnv
    }
    else {
        InitializeVS14Layout -Path $tooldir -Arch $Arch -HostEnv $HostEnv
    }
    
    Write-Host "Use $($instlock.Name) $($instlock.Version)"
}

# Initialize Visual Studio Environment
Function InitializeVisualStudio {
    param(
        [String]$ClangbuilderRoot,
        [ValidateSet("x86", "x64", "ARM", "ARM64")]
        [String]$Arch = "x64",
        [String]$InstanceId,
        [Switch]$Sdklow
    )
    if($InstanceId -eq "VisualCppTools"){
        return InitializeVisualCppTools -ClangbuilderRoot $ClangbuilderRoot -Arch $Arch -Sdklow:$Sdklow
    }
    $vsinstances = vswhere -prerelease -legacy -format json|ConvertFrom-JSON
    $vsinstance = $vsinstances|Where-Object {$_.instanceId -eq $InstanceId}
    Write-Host "Use Visual Studio $($vsinstance.installationVersion)"
    $ArgumentList = Get-ArchBatchString -InstanceId $InstanceId -Arch $Arch
    if ($vsinstance.instanceId.StartsWith("VisualStudio")) {
        $vcvarsall = "$($vsinstance.installationPath)\VC\vcvarsall.bat"
        if ($InstallId -eq "VisualStudio.14.0" -and $Sdklow) {
            Write-Host "Attention Please: Use Windows 8.1 SDK"
            $ArgumentList += " 8.1"
        }
        if (!(Test-Path $vcvarsall)) {
            Write-Host "$vcvarsall not found"
            return 1
        }
        Invoke-BatchFile -Path $vcvarsall -ArgumentList $ArgumentList
    }
    
    
    ## Now 15.4.26823.1 support Visual C++ for ARM64
    $FixedVer = [System.Version]::Parse("15.4.26823.0")
    $ver = [System.Version]::Parse($vsinstance.installationVersion)
    $vercmp = $ver.CompareTo($FixedVer)
    if ($Arch -eq "ARM64" -and $vercmp -le 0) {
        Write-Host "Use Enterprise WDK support ARM64"
        #Invoke-Expression "$PSScriptRoot\EnterpriseWDK.ps1"
        EnterpriseWDK -ClangbuilderRoot $ClangbuilderRoot
        return
    }
    $vcvarsall = "$($vsinstance.installationPath)\VC\Auxiliary\Build\vcvarsall.bat"
    
    $env:VS150COMNTOOLS = "$($vsinstance.installationPath)\Common7\Tools\"
    
    if ($Sdklow) {
        Write-Host "Attention Please: Use Windows 8.1 SDK"
        $ArgumentList += " 8.1"
    }
    
    if (!(Test-Path $vcvarsall)) {
        Write-Host "$vcvarsall not found"
        return 1;
    }
    
    Invoke-BatchFile -Path $vcvarsall -ArgumentList $ArgumentList
}

# Default Visual Studio Initialize Environemnt
Function DefaultVisualStudio {
    param(
        [String]$ClangbuilderRoot
    )
    $env:PATH = "$ClangbuilderRoot/pkgs/vswhere;$env:PATH"
    $vsinstalls=$null
    try {
        $vsinstalls = vswhere -prerelease -legacy -format json|ConvertFrom-JSON
    }
    catch {
        Write-Error "$_"
        Pop-Location
        exit 1
    }
    if ([System.Environment]::Is64BitOperatingSystem) {
        return (InitializeVisualStudio -ClangbuilderRoot $ClangbuilderRoot -Arch "x64" -InstanceId $vsinstalls[0].instanceId)
    }
    else {
        return (InitializeVisualStudio -ClangbuilderRoot $ClangbuilderRoot -Arch "x86" -InstanceId $vsinstalls[0].instanceId)
    }
}