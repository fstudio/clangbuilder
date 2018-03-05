## Powershell Package Initialize

Function Find-ExecutablePath {
    param(
        [String]$Path
    )
    if (!(Test-Path $Path)) {
        return $null
    }
    $files = Get-ChildItem -Path "$Path\*.exe"
    if ($files.Count -ge 1) {
        return $Path
    }
    if ((Test-Path "$Path\bin")) {
        return "$Path\bin"
    }
    if ((Test-Path "$Path\cmd")) {
        return "$Path\cmd"
    }
    return $null
}


Function Test-AddPath {
    param(
        [String]$Path
    )
    if (Test-Path $Path) {
        $env:PATH = $Path + [System.IO.Path]::PathSeparator + $env:PATH
    }
}

Function Test-ExecuteFile {
    param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Enter Execute Name")]
        [ValidateNotNullorEmpty()]
        [String]$ExeName
    )
    $myErr = @()
    Get-command -CommandType Application $ExeName -ErrorAction SilentlyContinue -ErrorVariable +myErr
    if ($myErr.count -eq 0) {
        return $True
    }
    return $False
}

Function Get-RegistryValueEx {
    param(
        [ValidateNotNullorEmpty()]
        [String]$Path,
        [ValidateNotNullorEmpty()]
        [String]$Key
    )
    if (!(Test-Path $Path)) {
        return 
    }
    (Get-ItemProperty $Path $Key).$Key
}


Function InitializePackageEnv {
    param(
        [String]$ClangbuilderRoot
    )
    $obj = Get-Content -Path "$ClangbuilderRoot\pkgs\packages.lock.json" |ConvertFrom-Json
    Get-Member -InputObject $obj -MemberType NoteProperty|ForEach-Object {
        $xpath = Find-ExecutablePath -Path "$ClangbuilderRoot\pkgs\$($_.Name)"
        if ($null -ne $xpath) {
            Test-AddPath -Path $xpath
        }
    }
    if (!(Test-ExecuteFile "git")) {
        $gitkey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
        $gitkey2 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
        if (Test-Path $gitkey) {
            $gitinstall = Get-RegistryValueEx $gitkey "InstallLocation"
            Test-AddPath "$gitinstall\bin"
        }
        elseif (Test-Path $gitkey2) {
            $gitinstall = Get-RegistryValueEx $gitkey2 "InstallLocation"
            Test-AddPath "$gitinstall\bin"
        }
    }
}


Function PMDownload {
    param(
        [String]$Uri, ### URI
        [String]$Path ### save to path
    )
    Write-Host "Download $Uri ..."
    $InternalUA = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
    if ($Uri.Contains("sourceforge.net")) {
        $InternalUA = "Clangbuilder/5.0"
    }
	
    try {
        Invoke-WebRequest -Uri $Uri -OutFile $Path -UserAgent $InternalUA -UseBasicParsing
    }
    catch {
        Write-Host -ForegroundColor Red "Download error: $_"
        return $false
    }
    return $true
}

Function Expand-Msi {
    param(
        [String]$Path,
        [String]$DestinationPath ### Full dir of destination path
    )
    $process = Start-Process -FilePath "msiexec" -ArgumentList "/a `"$Path`" /qn TARGETDIR=`"$DestinationPath`""  -PassThru -Wait
    if ($process.ExitCode -ne 0) {
        Write-Host -ForegroundColor Red "Expand-Msi: $Path failed. $($process.ExitCode)"
    }
    return $process.ExitCode
}

Function Initialize-ZipArchive {
    param(
        [String]$Path
    )
    $Item_ = Get-ChildItem -Path $Path
    if ($Item_.Count -eq 1) {
        if ($Item_[0] -isnot [System.IO.DirectoryInfo]) {
            return ;
        }
        $SubFile = $Item_[0].FullName
        Move-Item -Force -Path "$SubFile/*" -Destination $Path
        Remove-Item -Force -Recurse $SubFile
    }
}

Function ParseMsiArchiveFolder {
    param(
        [String]$Path,
        [String]$Subdir
    )
    $ProgramFilesSubDir = "$Path\$Subdir"
    if ((Test-Path $ProgramFilesSubDir)) {
        $Item_ = Get-ChildItem -Path $ProgramFilesSubDir
        if ($Item_.Count -eq 1) {
            if ($Item_[0] -isnot [System.IO.DirectoryInfo]) {
                Move-Item -Path $Item_[0].FullName -Destination $Path
                return $TRUE;
            }
            $SubFile = $Item_[0].FullName
            Move-Item -Force -Path "$SubFile/*" -Destination $Path
            Remove-Item -Force -Recurse $ProgramFilesSubDir
            return $TRUE;
        }
    }
    return $FALSE;
}

Function Initialize-MsiArchive {
    param(
        [String]$Path
    )
    Get-ChildItem -Path "$Path\*.msi"|ForEach-Object {
        Remove-Item -Path $_.FullName
    }
    if (ParseMsiArchiveFolder -Path $Path -Subdir "Program Files") {
        return 
    }
    if ( ParseMsiArchiveFolder  -Path $Path -Subdir "ProgramFiles64") {
        return 
    }
    ParseMsiArchiveFolder  -Path $Path -Subdir "Files"|Out-Null
}


Function Install-Package {
    param(
        [String]$ClangbuilderRoot,
        [String]$Name,
        [String]$Uri,
        [ValidateSet("zip", "msi", "exe")]
        [String]$Extension
    )

    $MyPackage = "$ClangbuilderRoot\pkgs\$Name.$Extension"
    $NewDir = "$ClangbuilderRoot\pkgs\$Name"
    $ret = PMDownload -Uri $Uri -Path "$MyPackage"
    if ($ret -eq $false) {
        return ;
    }
    Switch ($Extension) {
        "zip" {
            Expand-Archive -Path $MyPackage -DestinationPath $NewDir
            Initialize-ZipArchive -Path $NewDir
        } 
        "msi" {
            $ret = Expand-Msi -Path $MyPackage -DestinationPath  $NewDir
            if ($ret -eq 0) {
                Initialize-MsiArchive -Path $NewDir
            }
        } 
        "exe" {
            if (!(Test-Path $NewDir)) {
                mkdir $NewDir
            }
            Copy-Item -Path $MyPackage -Destination $NewDir -Force
        }
    }
    Remove-Item $MyPackage
}