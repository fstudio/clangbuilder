#!/usr/bin/env powershell
<#############################################################################
#  PkgInitialize.ps1
#  Note: Clangbuilder Package Installer
#  Date: 2017.02
#  Author:Force <forcemz@outlook.com>
##############################################################################>

Function Get-ClangbuilderToos {
    param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Package Download URL")]
        [String]$Uri,
        [Parameter(Position = 1, Mandatory = $True, HelpMessage = "Package Name")]
        [String]$Name,
        [Parameter(Position = 2, Mandatory = $True, HelpMessage = "Package Extension")]
        [String]$Extension
    )
    Write-Host "Downloading $Uri ..."
    $Result = Invoke-WebRequest -Uri $Uri -OutFile "$Name.$Extension" -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox -PassThru

}

Function Initialize-ZipArchive {
    param(
        [String]$Name
    )
    # Test Path
    $Item_ = Get-ChildItem -Path $Name
    if ($Item_.Count -eq 1) {
        if ($Item_[0].Attributes -ne 'Directory') {
            return true;
        }
        $SubFile = $Item_[0].FullName
        Move-Item -Force -Path "$SubFile/*" -Destination $Name
        Remove-Item -Force -Recurse $SubFile
    }
}

Function ParseMsiArchiveFolder {
    param(
        [String]$Name,
        [String]$Subdir
    )
    $ProgramFilesSubDir = "$Name\$Subdir"
    if ((Test-Path $ProgramFilesSubDir)) {
        $Item_ = Get-ChildItem -Path $ProgramFilesSubDir
        if ($Item_.Count -eq 1) {
            if ($Item_[0].Attributes -ne 'Directory') {
                Move-Item -Path $Item_[0].FullName -Destination $Name
                return $TRUE;
            }
            $SubFile = $Item_[0].FullName
            Move-Item -Force -Path "$SubFile/*" -Destination $Name
            Remove-Item -Force -Recurse $ProgramFilesSubDir
            return $TRUE;
        }
    }
    return $FALSE;
}

Function Initialize-MsiArchive {
    param(
        [String]$Name
    )
    $Item_ = Get-ChildItem -Path "$Name\*.msi"
    foreach ($i in $Item_) {
        Remove-Item -Path $i.FullName
    }
    $result = ParseMsiArchiveFolder -Name $Name -Subdir "Program Files"
    if (!$result) {
        $result = ParseMsiArchiveFolder -Name $Name -Subdir "ProgramFiles64"
        if (!$result) {
            $result = ParseMsiArchiveFolder -Name $Name -Subdir "Files"
        }
    }
    return $result
}


Function Initialize-ClangbuilderTools {
    param(
        [String]$Name,
        [String]$Extension
    )
    Switch ($Extension) {
        {$_ -eq "zip"} {
            Initialize-ZipArchive -Name $Name
        } {$_ -eq "msi"} {
            Initialize-MsiArchive -Name $Name
        }
    }
}

Function Expand-Msi {
    param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Msi Package Filename")]
        [String]$Path,
        [Parameter(Position = 1, Mandatory = $True, HelpMessage = "Unpack Directory")]
        [String]$DestinationPath
    )
    if (Test-Path $Path) {
        $retValue = 99
        $process = Start-Process -FilePath "msiexec" -ArgumentList "/a `"$Path`" /qn TARGETDIR=`"$DestinationPath`""  -PassThru -WorkingDirectory "$PSScriptRoot"
        Wait-Process -InputObject $process
        $retValue = $process.ExitCode
        if ($retValue -eq 0) {
            Write-Host "msiexec expend msi package success !"
            return $TRUE
        }
        Write-Error "Invoke msiexec expend package: $Path failed !"
    }
    else {
        Write-Error "Not Found Package: $Path"
    }
    return $FALSE
}

# Package Extension: zip msi and nuget
# Expand-Archive 
# Install Package
Function Install-ClangbuilderTools {
    param(
        [String]$Name,
        [ValidateSet("zip", "msi", "exe")]
        [String]$Extension
    )
    $File = $Name + "." + $Extension

    if (!(Test-Path $File)) {
        Write-Host "$File not exists, download failed !"
        return $False
    }

    Switch ($Extension) {
        {$_ -eq "zip"} {
            Expand-Archive -Path $File -DestinationPath $Name
        } {$_ -eq "msi"} {
            
            Expand-Msi -Path "$PWD\$File" -DestinationPath "$PWD\$Name"
        } {$_ -eq "exe"} {
            if (!(Test-Path $Name)) {
                mkdir $Name
            }
            Copy-Item -Path $File -Destination $Name -Force
        }
    }
}

$LastCurrentDir = Get-Location

$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot
$InstallDir = $ClangbuilderRoot + "/pkgs"

Set-Location $InstallDir

### SET Path
$IsWindows64 = [System.Environment]::Is64BitOperatingSystem


$PkgMetadata = Get-Content -Path "$ClangbuilderRoot/config/packages.json" |ConvertFrom-Json
$PkgCached = Get-Content -Path "$InstallDir/packages.lock.json" |ConvertFrom-Json
#Write-Host $PkgMetadata.Packages
$InstalledPkgMap = @{}

#Write-Host $PkgMetadata.Packages.Length

foreach ($i in $PkgMetadata.Packages) {
    $Name = $i.Name
    if ($i.Version -eq $PkgCached.$Name) {
        $InstalledPkgMap[$Name] = $PkgCached.$Name
        Write-Host -ForegroundColor Green "$Name is up to date !"
        continue 
    }
    #Invoke-WebRequest -Uri $i.X64URL -OutFile $Name.$i.Extension
    Write-Host "Initializing $Name"
    if ((Test-Path $Name)) {
        Rename-Item $Name "$Name.bak"
    }
    if ($null -eq $i.URL) {
        if ($IsWindows64) {
            Get-ClangbuilderToos -Uri $i.X64URL -Name $Name -Extension $i.Extension
        }
        else {
            Get-ClangbuilderToos -Uri $i.X86URL -Name $Name -Extension $i.Extension
        }
    }
    else {
        Get-ClangbuilderToos -Uri $i.URL -Name $Name -Extension $i.Extension
    }
    if (!(Install-ClangbuilderTools -Name $Name -Extension $i.Extension)) {
        Write-Host "Install $Name broken !"
    }
    $DownloadFile = $Name + "." + $i.Extension
    Remove-Item -Path $DownloadFile
    if ((Test-Path "$Name")) {
        if ((Test-Path "$Name.bak")) {
            Remove-Item -Force -Recurse "$Name.bak"
        }
        $InstalledPkgMap[$Name] = $i.Version
    }
    elseif ((Test-Path "$Name.bak")) {
        Move-Item "$Name.bak" "$Name"
        continue
    }
    if (Test-Path $Name) {
        Initialize-ClangbuilderTools -Name $Name -Extension $i.Extension
    }
}

ConvertTo-Json $InstalledPkgMap |Out-File -Force -FilePath "$InstallDir/packages.lock.json"

Set-Location $LastCurrentDir
