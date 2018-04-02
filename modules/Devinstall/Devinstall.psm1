## PowerShell Dev install engine


Function Devdownload {
    param(
        [String]$Uri, ### URI
        [String]$Path ### save to path
    )
    Write-Host "devdownload: $Uri ..."
    $InternalUA = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
    $xuri = [uri]$Uri
    # only sourceforget.net when ua is Browser, cannot download it
    if ($xuri.Host -eq "sourceforge.net") {
        $InternalUA = "clangbuilder/6.0"
    }
    try {
        if (Test-Path $Path) {
            Remove-Item -Force $Path
        }
        Invoke-WebRequest -Uri $Uri -OutFile $Path -UserAgent $InternalUA -UseBasicParsing
    }
    catch {
        Write-Host -ForegroundColor Red "download failed: $_"
        if (Test-Path $Path) {
            Remove-Item $Path
        }
        return $false
    }
    return $true
}

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

Function DevinitializeEnv {
    param(
        [String]$ClangbuilderRoot,
        [String]$Pkglocksdir
    )
    $pkgdir="$ClangbuilderRoot\bin\pkgs"
    Get-ChildItem "$Pkglocksdir\*.json" -ErrorAction SilentlyContinue|ForEach-Object{
        $xpath = Find-ExecutablePath -Path "$pkgdir\$($_.BaseName)"
        if ($null -ne $xpath) {
            Test-AddPath -Path $xpath
        }
    }
    if (!(Test-ExecuteFile "git")) {
        $gitkey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
        $gitkey2 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
        if (Test-Path $gitkey) {
            $gitinstall = Get-RegistryValueEx $gitkey "InstallLocation"
            Test-AddPath "${gitinstall}\bin"
        }
        elseif (Test-Path $gitkey2) {
            $gitinstall = Get-RegistryValueEx $gitkey2 "InstallLocation"
            Test-AddPath "${gitinstall}bin"
        }
    }
    return 0
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

