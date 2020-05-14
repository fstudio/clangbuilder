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
    $settingfile = "$ClangbuilderRoot\config\settings.json"
    if (!(Test-Path $settingfile)) {
        $settingfile = "$ClangbuilderRoot\config\settings.template.json"
    }
    Write-Host "Use $settingfile"
    if (!(Test-Path $settingfile)) {
        Write-Host -ForegroundColor Red "Not Enterprise WDK config file`nDownload URL: https://www.microsoft.com/en-us/software-download/windowsinsiderpreviewWDK"
        return 1
    }
    $settingsobj = Get-Content -Path "$settingfile" | ConvertFrom-Json

    $ewdkroot = $settingsobj.EnterpriseWDK
    if (!(Test-Path $ewdkroot)) {
        Write-Error "Enterprise WDK root $ewdkroot not found!"
        return 1
    }

    $ewdkmanifest = [xml](Get-Content -Path "$ewdkroot\Program Files\Windows Kits\10\SDKManifest.xml")

    $ewdkversion = $ewdkmanifest.FileList.PlatformIdentity.Split("=")[1]

    Write-Host "Initialize Windows 10 Enterprise WDK $Arch  Environment ..."
    Write-Host "Enterprise WDK Version: $ewdkversion"

    $vsnondir = "$ewdkroot\Program Files\Microsoft Visual Studio"

    $ewdkvsdirobj = Get-ChildItem -Path $vsnondir -ErrorAction SilentlyContinue
    if ($null -eq $ewdkvsdirobj) {
        Write-Host "Enterprise WDK Visual Studio Not Found"
        return 1
    }
    $VSProduct = $ewdkvsdirobj.BaseName
    $BuildTools = "$vsnondir\${VSProduct}\BuildTools"
    $xml = [xml](Get-Content -Path "$BuildTools\VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.props")
    $VCToolsVersion = $xml.Project.PropertyGroup.VCToolsVersion.'#text'
    $VisualCppPath = "$BuildTools\VC\Tools\MSVC\$VCToolsVersion"
    # Initialize Visual Studio version.
    if ($VSProduct -eq "2019") {
        $env:VS160COMNTOOLS = "$BuildTools\Common7\Tools\"
        Write-Host "Visual C++ Version: $VCToolsVersion`nUpdate `$env:VS160COMNTOOLS to: $env:VS160COMNTOOLS"
    }
    if ($VSProduct -eq "2017") {
        $env:VS150COMNTOOLS = "$BuildTools\Common7\Tools\"
        Write-Host "Visual C++ Version: $VCToolsVersion`nUpdate `$env:VS150COMNTOOLS to: $env:VS150COMNTOOLS"
    }

    $SdkBaseDir = "$ewdkroot\Program Files\Windows Kits\10"

    # Configuration Include Path
    [System.Text.StringBuilder]$Includedir = "$VisualCppPath\include;$VisualCppPath\atlmfc\include";
    Get-ChildItem -Path "$SdkBaseDir\include\$ewdkversion" | ForEach-Object { 
        [void]$Includedir.Append(";").Append($_.FullName)
    }
    $env:INCLUDE = $Includedir.ToString()
    $HostEnv = "x86"
    if ([System.Environment]::Is64BitOperatingSystem) {
        $HostEnv = "x64"
    }
    $Archlowpper = $Arch.ToLower()
    $sdklibdir = "$SdkBaseDir\lib\$ewdkversion"

    [System.Text.StringBuilder]$PathSb = $env:PATH
    [void]$PathSb.Append(";$VisualCppPath\bin\Host$HostEnv\$Archlowpper")
    # We need append $HostEnv to path, Because missing nmake.
    if ($Arch -ne $HostEnv) {
        [void]$PathSb.Append(";$VisualCppPath\bin\Host$HostEnv\$HostEnv")
    }

    $sdksbin = "$ewdkroot\Microsoft SDKs\Windows\v10.0A\bin"
    $netfxtoolsdirobj = Get-ChildItem -Path $sdksbin -ErrorAction SilentlyContinue
    $netfxtoolsdir = "NETFX 4.8 Tools"
    if ($null -ne $netfxtoolsdirobj) {
        $netfxtoolsdir = $netfxtoolsdirobj.BaseName
    }

    [void]$PathSb.Append(";$SdkBaseDir\bin\$EWDKVersion\$HostEnv")
    [void]$PathSb.Append(";$sdksbin\$netfxtoolsdir")
    [void]$PathSb.Append(";$BuildTools\MSBuild\Current\Bin")
    
    $env:PATH = $PathSb.Replace(";;", ";").ToString()

    [System.Text.StringBuilder]$LibSb = "$VisualCppPath\lib\$Archlowpper;$VisualCppPath\atlmfc\lib\$Archlowpper"
    [void]$LibSb.Append(";$sdklibdir\km\$Archlowpper;$sdklibdir\um\$Archlowpper;$sdklibdir\ucrt\$Archlowpper")
    $env:LIB = $LibSb.ToString()

    [System.Text.StringBuilder]$LibPathSb = "$VisualCppPath\lib\$Archlowpper;$VisualCppPath\atlmfc\lib\$Archlowpper"
    [void]$LibPathSb.Append("$SdkBaseDir\UnionMetadata\$EWDKVersion\;$SdkBaseDir\References\$EWDKVersion\")
    $env:LIBPATH = $LibPathSb.ToString()

    [environment]::SetEnvironmentVariable("VSENV_INITIALIZED", "VisualStudio.EWDK")
    return 0
}

# Initialize Visual Studio Environment
Function InitializeVisualStudio {
    param(
        [String]$ClangbuilderRoot,
        [ValidateSet("x86", "x64", "ARM", "ARM64")]
        [String]$Arch = "x64",
        [String]$InstanceId,
        [String]$InstallationVersion # installationVersion
    )
    if ($null -ne $env:VSENV_INITIALIZED) {
        return 0
    }
    if ([String]::IsNullOrEmpty($InstanceId)) {
        return 1
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
    $ver = [System.Version]::Parse($vsinstance.installationVersion)
    $vcvarsall = "$($vsinstance.installationPath)\VC\Auxiliary\Build\vcvarsall.bat"
    $vscommtools = "VS$($ver.Major)0COMNTOOLS"
    [environment]::SetEnvironmentVariable($vscommtools, "$($vsinstance.installationPath)\Common7\Tools\")
    $vscommdir = [environment]::GetEnvironmentVariable($vscommtools)
    Write-Host "Update `$env:$vscommtools to: $vscommdir"
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
    }
    catch {
        Write-Error "$_"
        Pop-Location
        return 1
    }
    if ($null -eq $vsinstalls -or $vsinstalls.Count -eq 0) {
        return 1
    }
    $Pos = 0
    $Preversion = 1602
    for ($i = 0; $i -lt $vsinstalls.Count; $i++) {
        $vv = $vsinstalls.installationVersion.Split(".")
        $ver = [int]$vv[0]*100 + [int]$vv[1]
        if ($ver -ge $Preversion) {
            $Pos = $i
            $Preversion = $ver
        }
    }
    return (InitializeVisualStudio -ClangbuilderRoot $ClangbuilderRoot -Arch $Arch -InstanceId $vsinstalls[$Pos].instanceId)
}