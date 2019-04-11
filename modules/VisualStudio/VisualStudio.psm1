# VisualStudio Modules

Function Invoke-BatchFile {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [string] $ArgumentList
    )
    Set-StrictMode -Version Latest
    $tempFile = [IO.Path]::GetTempFileName()

    cmd.exe /c " `"$Path`" $argumentList && set > `"$tempFile`" " | Out-Host
    ## Go through the environment variables in the temp file.
    ## For each of them, set the variable in our local environment.
    Get-Content $tempFile | ForEach-Object {
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



Function InitializeEnterpriseWDK {
    param(
        [String]$Arch = "ARM64",
        [String]$ClangbuilderRoot
    )
    $EWDKFile = "$ClangbuilderRoot\config\ewdk.json"
    if (!(Test-Path $EWDKFile)) {
        $EWDKFile = "$ClangbuilderRoot\config\ewdk.template.json"
    }
    Write-Host "Use $EWDKFile"
    if (!(Test-Path $EWDKFile)) {
        Write-Host -ForegroundColor Red "Not Enterprise WDK config file`nDownload URL: https://www.microsoft.com/en-us/software-download/windowsinsiderpreviewWDK"
        return 1
    }
    $EWDKObj = Get-Content -Path "$EWDKFile" | ConvertFrom-Json
    $EWDKPath = $EWDKObj.Path
    if (!(Test-Path $EWDKPath)) {
        Write-Error "Not Enterprise WDK directory !"
        return 1
    }
    $ewdkmanifest = [xml](Get-Content -Path "$EWDKPath\Program Files\Windows Kits\10\SDKManifest.xml")

    $EWDKVersion = $ewdkmanifest.FileList.PlatformIdentity.Split("=")[1]

    Write-Host "Initialize Windows 10 Enterprise WDK $Arch  Environment ..."
    Write-Host "Enterprise WDK Version: $EWDKVersion"

    $ewdkdirobj = Get-ChildItem -Path "$EWDKPath\Program Files\Microsoft Visual Studio\" -ErrorAction SilentlyContinue
    if ($null -eq $ewdkdirobj) {
        Write-Host "Enterprise WDK Visual Studio Not Found"
        return 1
    }
    $VSProduct = $ewdkdirobj.BaseName
    $BuildTools = "$EWDKPath\Program Files\Microsoft Visual Studio\${VSProduct}\BuildTools"
    $SdkBaseDir = "$EWDKPath\Program Files\Windows Kits\10"
    $xml = [xml](Get-Content -Path "$BuildTools\VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.props")
    $VCToolsVersion = $xml.Project.PropertyGroup.VCToolsVersion.'#text'
    if ($VSProduct -eq "2019") {
        $env:VS160COMNTOOLS = "$BuildTools\Common7\Tools\"
        Write-Host "Visual C++ Version: $VCToolsVersion`nUpdate `$env:VS160COMNTOOLS to: $env:VS150COMNTOOLS"
    }
    if ($VSProduct -eq "2017") {
        $env:VS150COMNTOOLS = "$BuildTools\Common7\Tools\"
        Write-Host "Visual C++ Version: $VCToolsVersion`nUpdate `$env:VS150COMNTOOLS to: $env:VS150COMNTOOLS"
    }

    $VisualCppPath = "$BuildTools\VC\Tools\MSVC\$VCToolsVersion"
    # Configuration Include Path
    $env:INCLUDE = "$VisualCppPath\include;$VisualCppPath\atlmfc\include"
    $includedirs = Get-ChildItem -Path "$SdkBaseDir\include\$EWDKVersion" | ForEach-Object { $_.FullName }
    foreach ($_i in $includedirs) {
        $env:INCLUDE = "$env:INCLUDE;$_i"
    }
    if ([System.Environment]::Is64BitOperatingSystem) {
        $HostEnv = "x64"
    }
    else {
        $HostEnv = "x86"
    }
    $Archlowpper = $Arch.ToLower()
    $SDKLIB = "$SdkBaseDir\lib\$EWDKVersion"
    ### FIX EWDK of Non ARM Arch
    if (!$Arch.StartsWith("ARM") -and $Arch -ne $HostEnv) {
        $env:PATH += ";$VisualCppPath\bin\Host$HostEnv\$Archlowpper;$VisualCppPath\bin\Host$HostEnv\$HostEnv"
    }
    else {
        $env:PATH += ";$VisualCppPath\bin\Host$HostEnv\$Archlowpper"
    }
    $netfxtoolsdirobj = Get-ChildItem -Path "$EWDKPath\Microsoft SDKs\Windows\v10.0A\bin\" -ErrorAction SilentlyContinue
    $netfxtoolsdir = "NETFX 4.8 Tools"
    if ($null -ne $netfxtoolsdirobj) {
        $netfxtoolsdir = $netfxtoolsdirobj.BaseName
    }
    $env:PATH += ";$SdkBaseDir\bin\$EWDKVersion\$HostEnv;"
    $env:PATH += "$EWDKFile\Program Files\Microsoft SDKs\Windows\v10.0A\bin\${netfxtoolsdir};$BuildTools\MSBuild\15.0\Bin"
    $env:LIB = "$VisualCppPath\lib\$Archlowpper;$VisualCppPath\atlmfc\lib\$Archlowpper;"
    $env:LIB += "$SDKLIB\km\$Archlowpper;$SDKLIB\um\$Archlowpper;$SDKLIB\ucrt\$Archlowpper"
    $env:LIBPATH = "$VisualCppPath\lib\$Archlowpper;$VisualCppPath\atlmfc\lib\$Archlowpper;"
    $env:LIBPATH = "$SdkBaseDir\UnionMetadata\$EWDKVersion\;$SdkBaseDir\References\$EWDKVersion\;"
    [environment]::SetEnvironmentVariable("VSENV_INITIALIZED", "VisualStudio.EWDK")
    return 0
}

Function InitializeVS2017Layout {
    param(
        [String]$Path,
        [String]$Arch,
        [String]$HostEnv = "x64"
    )
    $env:INCLUDE = "$env:INCLUDE;$Path\include;$Path\atlmfc\include;"
    if ($HostEnv -eq $Arch) {
        $env:PATH = "$env:PATH;$Path\bin\Host$Arch\$Arch"
    }
    else {
        $env:PATH = "$env:PATH;$Path\bin\Host$HostEnv\$Arch;$Path\bin\Host$HostEnv\$HostEnv"
    }
    $env:LIB = "$env:LIB;$Path\lib\$Arch;$Path\atlmfc\lib\$Arch"
}

Function InitializeVS14Layout {
    param(
        [String]$Path,
        [String]$Arch,
        [String]$HostEnv
    )
    if ($HostEnv -eq "x64") {
        $HostEnv = "amd64" #
    }
    ### FIX x86 Host Env
    if ($Arch -eq "x64") {
        $Arch = "amd64"
    }
    $Archlowpper = $Arch.ToLower()
    Write-Host "Visual Studio 14 Layout Arch: $Arch Host: $HostEnv"
    $env:INCLUDE = "$env:INCLUDE;$Path\include;$Path\atlmfc\include;"
    if ($Archlowpper -eq "x86") {
        $env:LIB = "$env:LIB;$Path\lib"
    }
    else {
        $env:LIB = "$env:LIB;$Path\lib\$Archlowpper"
    }
    if ($HostEnv -eq "x86") {
        $env:PATH = "$Path\bin;$env:PATH"
    }
    else {
        $env:PATH = "$Path\bin\amd64;$env:PATH"
    }
    if ($HostEnv -ne $Archlowpper) {
        Write-Host "xxx $Path\bin\${HostEnv}_$Archlowpper"
        $env:PATH = "$Path\bin\${HostEnv}_$Archlowpper;$env:PATH"
    }
}

#\Microsoft\Microsoft SDKs\Windows\v10.0
Function InitializeWinSdk10 {
    param(
        [String]$Arch,
        [String]$HostEnv = "x64"
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
    if (Test-Path "${installdir}include\$version\cppwinrt") {
        $env:INCLUDE += ";${installdir}include\$version\cppwinrt"
    }
    $env:PATH = "$env:PATH;${installdir}bin\$version\$HostEnv"
}

Function InitializeUCRT {
    param(
        [String]$Arch,
        [String]$HostEnv = "x64"
    )
    $sdk10 = "HKLM:SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0"
    if (!(Test-Path $sdk10)) {
        $sdk10 = "HKLM:SOFTWARE\Microsoft\Microsoft SDKs\Windows\v10.0"
    }
    $pt = Get-ItemProperty -Path $sdk10
    $version = "$($pt.ProductVersion).0"
    $installdir = $pt.InstallationFolder
    $env:INCLUDE = "$env:INCLUDE;${installdir}include\$version\ucrt"
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

Function InitializeVisualCppTools {
    param(
        [String]$ClangbuilderRoot,
        [ValidateSet("x86", "x64", "ARM", "ARM64")]
        [String]$Arch = "x64",
        [String]$InstanceId,
        [Switch]$Sdklow
    )
    $VisualCppToolsInstallDir = "$ClangbuilderRoot\bin\utils\msvc"
    $LockFile = "$VisualCppToolsInstallDir\VisualCppTools.lock.json"
    if (!(Test-Path $LockFile)) {
        Write-Host -ForegroundColor Red "Not Found VisualCppTools.Community.Daily
        Please run '$ClangbuilderRoot\script\VisualCppToolsFetch.bat'"
        return 1
    }
    $instlock = Get-Content -Path $LockFile | ConvertFrom-Json
    $HostEnv = "x86"
    if ([System.Environment]::Is64BitOperatingSystem) {
        $HostEnv = "x64"
    }
    if ($Sdklow) {
        InitailizeWinSdk81 -Arch $Arch -HostEnv $HostEnv
    }
    else {
        InitializeWinSdk10  -Arch $Arch -HostEnv $HostEnv
    }
    $env:VisualCppToolsPath = $ClangbuilderRoot + "\bin\utils\msvc\" + $instlock.Path
    $tooldir = $env:VisualCppToolsPath + "\lib\native"
    $env:VSPropsFile = $env:VisualCppToolsPath + "\build\native\" + $instlock.Name + ".props"
    Write-Host "MSBuild can import $env:VSPropsFile"
    if ($instlock.Name.Contains("VS2017Layout")) {
        InitializeVS2017Layout -Path $tooldir -Arch $Arch -HostEnv $HostEnv
    }
    else {
        InitializeVS14Layout -Path $tooldir -Arch $Arch -HostEnv $HostEnv
    }
    [environment]::SetEnvironmentVariable("VSENV_INITIALIZED", "VisualStudio.CppTools")
    Write-Host "Use $($instlock.Name) $($instlock.Version)"
    return 0
}

Function Test-ExeCommnad {
    param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Enter Execute Name")]
        [ValidateNotNullorEmpty()]
        [String]$ExeName
    )
    $myErr = @()
    Get-Command -CommandType Application $ExeName -ErrorAction SilentlyContinue -ErrorVariable +myErr
    if ($myErr.count -eq 0) {
        return $True
    }
    return $False
}

Function FixVisualStudioSdkPath {
    if (Test-ExeCommnad "rc") {
        return ;
    }
    $sdk10 = "HKLM:SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0"
    if (!(Test-Path $sdk10)) {
        $sdk10 = "HKLM:SOFTWARE\Microsoft\Microsoft SDKs\Windows\v10.0"
    }
    $HostEnv = "x86"
    if ([System.Environment]::Is64BitOperatingSystem) {
        $HostEnv = "x64"
    }
    $sdkinfo = Get-ItemProperty -Path $sdk10
    $version = $sdkinfo.ProductVersion + ".0"
    $installdir = $sdkinfo.InstallationFolder
    $SDKPath = "${installdir}bin\$version\$HostEnv"
    Write-Host "Need use New SDK Path: $SDKPath"
    $env:PATH = "$env:PATH;$SDKPath"
}

# Initialize Visual Studio Environment
Function InitializeVisualStudio {
    param(
        [String]$ClangbuilderRoot,
        [ValidateSet("x86", "x64", "ARM", "ARM64")]
        [String]$Arch = "x64",
        [String]$InstanceId,
        [String]$InstallationVersion, # installationVersion
        [Switch]$Sdklow
    )
    if ($null -ne $env:VSENV_INITIALIZED) {
        return 0
    }
    if ([String]::IsNullOrEmpty($InstanceId)) {
        return 1
    }
    if ($InstanceId -eq "VisualCppTools") {
        Write-Host -ForegroundColor Red "VisualCppTools is deprecated"
        return (InitializeVisualCppTools -ClangbuilderRoot $ClangbuilderRoot -Arch $Arch -Sdklow:$Sdklow)
    }
    if ($InstanceId -eq "VisualStudio.EWDK") {
        return (InitializeEnterpriseWDK -ClangbuilderRoot $ClangbuilderRoot -Arch $Arch)
    }
    $vsinstances = $null
    #Write-Host "$InstallationVersion"
    if ($InstanceId.StartsWith("VisualStudio.")) {
        $vsinstances = vswhere -products * -prerelease -legacy -format json | ConvertFrom-Json
    }
    else {
        $vsinstances = vswhere -products * -prerelease -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64  -format json | ConvertFrom-Json
    }
    #Microsoft.VisualStudio.Component.VC.Tools.x86.x64
    if ($null -eq $vsinstances -or $vsinstances.Count -eq 0) {
        return 1
    }
    $vsinstance = $vsinstances | Where-Object { $_.instanceId -eq $InstanceId }
    if ($null -eq $vsinstance) {
        Write-Host -ForegroundColor Red "Please check Visual Studio Is Included Microsoft.VisualStudio.Component.VC.Tools"
        return 1
    }
    $vsversion = $vsinstance.installationVersion
    [environment]::SetEnvironmentVariable("VSENV_VERSION", "$vsversion")
    Write-Host "Use Visual Studio $vsversion $Arch"
    $ArgumentList = Get-ArchBatchString -InstanceId $InstanceId -Arch $Arch
    if ($vsinstance.instanceId.StartsWith("VisualStudio")) {
        $vcvarsall = "$($vsinstance.installationPath)\VC\vcvarsall.bat"
        if ($InstanceId -eq "VisualStudio.14.0" -and $Sdklow) {
            Write-Host "Attention Please: Use Windows 8.1 SDK"
            $ArgumentList += " 8.1"
        }
        if (!(Test-Path $vcvarsall)) {
            Write-Host "$vcvarsall not found"
            return 1
        }
        Invoke-BatchFile -Path $vcvarsall -ArgumentList $ArgumentList
        if ($InstanceId -eq "VisualStudio.14.0") {
            FixVisualStudioSdkPath
        }
        [environment]::SetEnvironmentVariable("VSENV_INITIALIZED", "$InstanceId")
        return 0
    }

    $ver = [System.Version]::Parse($vsinstance.installationVersion)
    $vcvarsall = "$($vsinstance.installationPath)\VC\Auxiliary\Build\vcvarsall.bat"
    $vscommtools = "VS$($ver.Major)0COMNTOOLS"
    Set-Variable -Name "env:$vscommtools" -Value "$($vsinstance.installationPath)\Common7\Tools\"
    $vscommdir = Get-Variable -Name "env:$vscommtools" -ValueOnly
    Write-Host "Update `$env:$vscommtools to: $vscommdir"
    if ($Sdklow) {
        Write-Host "Attention Please: Use Windows 8.1 SDK"
        $ArgumentList += " 8.1"
    }
    if (!(Test-Path $vcvarsall)) {
        Write-Host "$vcvarsall not found"
        return 1
    }
    Invoke-BatchFile -Path $vcvarsall -ArgumentList $ArgumentList
    [environment]::SetEnvironmentVariable("VSENV_INITIALIZED", "VisualStudio.$ver")
    return 0
}

# Default Visual Studio Initialize Environemnt
Function DefaultVisualStudio {
    param(
        [String]$ClangbuilderRoot,
        [String]$Arch
    )
    if ($Arch.Length -eq 0) {
        if ([System.Environment]::Is64BitOperatingSystem) {
            $Arch = "x64"
        }
        else {
            $Arch = "x86"
        }
    }
    $vsinstalls = $null
    try {
        # Found not preleased
        $vsinstalls = vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -format json | ConvertFrom-Json
        if ($vsinstalls.Count -eq 0) {
            $vsinstalls = vswhere -products * -prerelease -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -format json | ConvertFrom-Json
        }
        if ($vsinstalls.Count -eq 0) {
            ### use fallback fules
            $vsinstalls = vswhere -products * -prerelease -legacy -format json | ConvertFrom-Json
        }
    }
    catch {
        Write-Error "$_"
        Pop-Location
        return 1
    }
    if ($null -eq $vsinstalls -or $vsinstalls.Count -eq 0) {
        return 1
    }
    return (InitializeVisualStudio -ClangbuilderRoot $ClangbuilderRoot -Arch $Arch -InstanceId $vsinstalls[0].instanceId)
}