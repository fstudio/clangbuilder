## PowerShell Dev install engine

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

Function IsAcceptPath {
    param(
        [String]$Str
    )
    if ([String]::IsNullOrEmpty($Str)) {
        return $false
    }
    if ([String]::IsNullOrWhiteSpace($Str)) {
        return $false
    }
    if ($Str -eq ".." -or $Str -eq ".") {
        return $false
    }
    return $true
}

Function DevinitializeEnv {
    param(
        [String]$ClangbuilderRoot
    )
    $pkgdir = "$ClangbuilderRoot\bin\pkgs"
    $linkdir = "$ClangbuilderRoot\bin\pkgs\.linked"
    $paths = $env:PATH.Split(";")
    Get-ChildItem "$ClangbuilderRoot\bin\pkgs\.locks\*.json" -ErrorAction SilentlyContinue | ForEach-Object {
        $xobj = Get-Content $_.FullName  -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        $pkgname = $_.BaseName
        $mount = "$($xobj.mount)"
        if ($xobj.linked -eq $true) {
            # Nothing to do
        }
        elseif (IsAcceptPath -Str $mount) {
            $xpath = Find-ExecutablePath -Path "$pkgdir\$pkgname\$mount"
            if ($null -ne $xpath -and !($paths.Contains($xpath))) {
                #Write-Host "Add $pkgname"
                Test-AddPath -Path $xpath
            }
        }
        else {
            $xpath = Find-ExecutablePath -Path "$pkgdir\$pkgname"
            if ($null -ne $xpath -and !($paths.Contains($xpath))) {
                #Write-Host "Add $pkgname"
                Test-AddPath -Path $xpath
            }
        }
    }
    if (!$paths.Contains($linkdir)) {
        if (Test-Path $linkdir) {
            $env:PATH = $linkdir + [System.IO.Path]::PathSeparator + $env:PATH
        }
    }
    $cmd = Get-Command -CommandType Application "git.exe" -ErrorAction SilentlyContinue
    if ($null -eq $cmd) {
        $gitkey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
        $gitkey2 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
        if (Test-Path $gitkey) {
            $gitinstall = Get-RegistryValueEx $gitkey "InstallLocation"
            Test-AddPath "${gitinstall}bin"
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

Function Initialize-MsiArchive {
    param(
        [String]$Path
    )
    Get-ChildItem -Path "$Path\*.msi" | ForEach-Object {
        Remove-Item -Path $_.FullName
    }
    Remove-Item -Path "$Path\Windows" -Recurse -ErrorAction SilentlyContinue
    $skipdirs = "Program Files", "ProgramFiles64", "PFiles", "Files"
    foreach ($d in $skipdirs) {
        $sd = "$Path/$d"
        if (Test-Path $sd) {
            $ssdir = Get-ChildItem -Path $sd
            if ($ssdir.Count -eq 1) {
                if ($ssdir[0] -isnot [System.IO.DirectoryInfo]) {
                    Move-Item -Path $ssdir[0].FullName -Destination $Path
                    return
                }
                $xsubdir = $ssdir[0].FullName
                Move-Item -Force -Path "$xsubdir/*" -Destination $Path
                Remove-Item -Force -Recurse $sd
            }
        }
    }
}

