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


Function PreInitializeEnv {
    $cmd = Get-Command -CommandType Application "git.exe" -ErrorAction SilentlyContinue
    if ($null -ne $cmd) {
        # find git in path
        return 
    }
    $NativeKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
    $WOW6432NodeKey = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
    if (Test-Path $NativeKey) {
        $installdir = Get-RegistryValueEx $NativeKey "InstallLocation"
        $gitpath = Join-Path $installdir "cmd"
        Test-AddPath $gitpath
        return 
    }
    if (Test-Path $WOW6432NodeKey) {
        $installdir = Get-RegistryValueEx $WOW6432NodeKey "InstallLocation"
        $gitpath = Join-Path $installdir "cmd"
        Test-AddPath $gitpath
        return
    }
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
    PreInitializeEnv
    return 0
}

Function Initialize-FlatTarget {
    param(
        [String]$TopDir,
        [String]$MoveTo
    )
    $items = Get-ChildItem -Path $TopDir
    if ($items.Count -ne 1) {
        return 
    }
    if ($items[0] -isnot [System.IO.DirectoryInfo]) {
        return ;
    }
    $childdel = $items[0].FullName
    $checkdir = $childdel
    for ($i = 0; $i -lt 10; $i++) {
        $childs = Get-ChildItem $checkdir
        if ($childs.Count -eq 1 -and $childs[0] -is [System.IO.DirectoryInfo]) {
            $checkdir = $childs[0].FullName
            continue;
        }
        Move-Item -Force -Path "$checkdir/*" -Destination $MoveTo
        Remove-Item -Force -Recurse $childdel
        return 
    }
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
            Initialize-FlatTarget -TopDir $sd -MoveTo $Path
        }
    }
}

