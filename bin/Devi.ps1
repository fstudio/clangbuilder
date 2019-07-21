#!/usr/bin/env pwsh
# devi tools

."$PSScriptRoot\PreInitialize.ps1"
Import-Module -Name "$ClangbuilderRoot\modules\Devi" # Package Manager
Import-Module -Name  "$ClangbuilderRoot\modules\Utils"

Function PrintUsage {
    Write-Host "devi portable package manager 1.1
Usage: devi cmd package-name
    list         list installed package
    search       search ported package
    install      install package
    uninstall    uninstall package
    upgrade      upgrade all upgradeable packages
    help         print help message
    version      print devi version and exit
"
}
Function CMDList {
    param(
        [String]$Pkglocksdir
    )
    Get-ChildItem -Path "$Pkglocksdir/*.json" | ForEach-Object {
        $obj = Get-Content -Path $_.FullName -ErrorAction SilentlyContinue | ConvertFrom-Json  -ErrorAction SilentlyContinue
        if ($null -eq $obj -or ($null -eq $obj.version) ) {
            Write-Host -ForegroundColor Red "Invalid file locks: $($_.FullName)"
            return
        }
        $_.BaseName.PadRight(20) + $obj.version
    }
}

Function CMDSearchOne {
    param(
        [String]$Root,
        [String]$Port
    )
    $Portfile = "$Root/ports/$Port.json"
    $cj = Get-Content "$Portfile"  -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($null -eq $cj) {
        Write-Host -ForegroundColor Red "Port: $Port not found. path: $Portfile"
        return
    }
    $xversion = $cj.version
    "$Port".PadRight(20) + "$xversion".PadRight(20) + $cj.description
}


# search
Function CMDSearch {
    param(
        [String]$Root
    )
    Write-Host -ForegroundColor Green "devi portable package manager, found ports:"
    Get-ChildItem -Path "$Root/ports/*.json" | ForEach-Object {
        $cj = Get-Content $_.FullName  -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($null -ne $cj) {
            $xversion = $cj.version
            "$($_.BaseName)".PadRight(20) + "$xversion".PadRight(20) + $cj.description
        }
    }
}




Function CMDUninstall {
    param(
        [String]$ClangbuilderRoot,
        [String]$Name
    )
    $lockfile = "$ClangbuilderRoot/bin/pkgs/.locks/$Name.json"
    if (!(Test-Path "$Pkglocksdir/$Name.json")) {
        Write-Host -ForegroundColor Red "not found $Name in $Pkglocksdir"
    }
    else {
        $instmd = Get-Content $lockfile  -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($null -ne $instmd.links) {
            foreach ($lkfile in $instmd.links) {
                $xlinked = "$ClangbuilderRoot/bin/pkgs/.linked/$lkfile"
                if (Test-Path $xlinked) {
                    Remove-Item -Force $xlinked
                }
            }
        }
        Remove-Item $lockfile -Force
    }

    $pkgdir = "$ClangbuilderRoot/bin/pkgs/$Name"
    if (Test-Path $pkgdir) {
        Remove-Item -Force -Recurse  $pkgdir  -ErrorAction SilentlyContinue | Out-Null
    }
    Write-Host -ForegroundColor Yellow "devi: uninstall $Name done."
}

# Inno Setup unpack
# innounp.exe -x $filename -dDIR
Function CMDInstall {
    param(
        [String]$ClangbuilderRoot,
        [String]$Pkglocksdir,
        [String]$Name
    )
    if (!(Test-Path "$ClangbuilderRoot/ports/$Name.json")) {
        Write-Host -ForegroundColor Red "devi: $Name not yet ported."
        return $false
    }
    $devpkg = Get-Content "$ClangbuilderRoot/ports/$Name.json"  -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ( $null -eq $devpkg) {
        Write-Host -ForegroundColor Red "`'$Name`' not yet ported."
        return $false
    }
    if ($null -eq $devpkg.version) {
        Write-Host -ForegroundColor Red "`'$Name`' port config invalid."
        return $false
    }
    $ext = $devpkg.extension
    $AllowedExtensions = "exe", "zip", "msi", "7z"
    if (!$AllowedExtensions.Contains($ext)) {
        Write-Host -ForegroundColor Red "extension `'$ext`' not allowed."
        return $false
    }
    $sevenzipbin = "$ClangbuilderRoot\bin\pkgs\7z\7z.exe"
    if ($devpkg.extension -eq "7z") {
        if (!(Test-Path $sevenzipbin)) {
            Write-Host -ForegroundColor Red "This package extension is `'7z`', but 7z not install. Please run devi install 7z."
            return $false
        }
    }

    $oldtable = Get-Content "$Pkglocksdir/$Name.json"  -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    $pkversion = $devpkg.version
    if ($null -ne $oldtable -and $oldtable.version -eq $pkversion) {
        Write-Host -ForegroundColor Yellow "devi: $Name is up to date. version: $($oldtable.version)"
        return $true
    }
    $xurl = $devpkg.url
    if ([System.Environment]::Is64BitOperatingSystem -and ($null -ne $devpkg.url64)) {
        $xurl = $devpkg.url64
    }
    $besturl = $null
    if ($xurl -is [array]) {
        $besturl = Test-BestSourcesURL -Urls $xurl
    }
    else {
        $besturl = $xurl
    }
    if ($null -eq $besturl) {
        Write-Host -ForegroundColor Red "$Name not provider download url!"
        return $false
    }

    $pkgfile = "$ClangbuilderRoot\bin\pkgs\$Name.$ext"
    $installdir = "$ClangbuilderRoot\bin\pkgs\$Name"
    $tempdir = "$installdir.$PID"
    if (!(Devdownload -Uri $besturl -Path "$pkgfile")) {
        return $false
    }
    try {
        if ((Test-Path $installdir)) {
            Move-Item -Force  $installdir $tempdir -ErrorAction SilentlyContinue | Out-Null
        }
        Switch ($ext) {
            "zip" {
                Expand-Archive -Path $pkgfile -DestinationPath $installdir
                Initialize-ZipArchive -Path $installdir
            }
            "msi" {
                $ret = Expand-Msi -Path $pkgfile -DestinationPath  $installdir
                if ($ret -ne 0) {
                    throw "Expand $pkgfile failed"
                }
                Initialize-MsiArchive -Path $installdir
            }
            "exe" {
                if (!(Test-Path $installdir)) {
                    mkdir $installdir | Out-Null
                }
                Copy-Item -Path $pkgfile -Destination $installdir -Force
            }
            "7z" {
                $ret = ProcessExec -FilePath $sevenzipbin -Args "e -spf -y `"$pkgfile`" `"-o$installdir`""
                if ($ret -ne 0) {
                    throw "decompress $pkgfile by 7z failed"
                }
                Initialize-ZipArchive -Path $installdir
            }
        }
    }
    catch {
        Write-Host -ForegroundColor Red "$_"
        if (!(Test-Path $installdir) -and (Test-Path $tempdir)) {
            Move-Item -Force $tempdir $installdir -ErrorAction SilentlyContinue | Out-Null
        }
        if (Test-Path $tempdir) {
            Remove-Item -Force -Recurse  $tempdir  -ErrorAction SilentlyContinue | Out-Null
        }
        return $false
    }
    $versiontable = @{ }
    $versiontable["version"] = $pkversion
    [System.Collections.ArrayList]$mlinks = @()
    if ($null -ne $oldtable.links) {
        [System.Collections.ArrayList]$lav = @()
        if ($null -ne $devpkg.launcher) {
            foreach ($l in $devpkg.launcher) {
                $lna = Split-Path -Leaf $l
                $lav.Add($lna) | Out-Null
            }
        }
        foreach ($f in $oldtable.links) {
            if ($lav.Contains($f)) {
                Write-Host -ForegroundColor Green "Keep launcher: $f, you can run mklauncher rebuild it."
                $mlinks.Add($f) | Out-Null
                continue
            }
            $launcherfile = "$ClangbuilderRoot/bin/pkgs/.linked/" + $f
            if (Test-Path $launcherfile) {
                Remove-Item -Force -Recurse $launcherfile
            }
        }
    }

    if ($null -ne $devpkg.links ) {
        if (!(Test-Path "$ClangbuilderRoot/bin/pkgs/.linked")) {
            mkdir "$ClangbuilderRoot/bin/pkgs/.linked" | Out-Null
        }
        try {
            foreach ($i in $devpkg.links) {
                $srcfile = "$installdir/$i"
                $item = Get-Item $srcfile
                $symlinkfile = "$ClangbuilderRoot/bin/pkgs/.linked/" + $item.Name
                if (Test-Path $symlinkfile) {
                    Remove-Item -Force -Recurse $symlinkfile
                }
                if (Test-Path "$ClangbuilderRoot/bin/blast.exe" ) {
                    &"$ClangbuilderRoot/bin/blast.exe" --link  "$($item.FullName)" "$symlinkfile"
                }
                else {
                    $xsymlinkfile = $symlinkfile.Replace("/", "\")
                    cmd /c mklink "$xsymlinkfile" "$($item.FullName)" ## < Windows 10 need Admin
                }
                if ($LASTEXITCODE -ne 0) {
                    throw "failed create symlink: $symlinkfile"
                }
                $mlinks.Add($item.Name) | Out-Null
                Write-Host -ForegroundColor Green "link $($item.FullName) to $symlinkfile success."
            }
        }
        catch {
            Write-Host -ForegroundColor Red "create symbolic link failed: $_"
        }
    }
    if ($mlinks.Count -gt 0) {
        $versiontable["links"] = $mlinks
        $versiontable["linked"] = $true
    }
    if ($null -ne $devpkg.mount) {
        $versiontable["mount"] = $devpkg.mount
    }
    ConvertTo-Json $versiontable | Out-File -Force -FilePath "$Pkglocksdir/$Name.json"
    if (Test-Path $tempdir) {
        Remove-Item -Force -Recurse $tempdir  -ErrorAction SilentlyContinue | Out-Null
    }
    Remove-Item $pkgfile -Force -ErrorAction SilentlyContinue | Out-Null ##ignore remove-item return del/null
    Write-Host -ForegroundColor Green "devi: install $Name success, version: $pkversion"
    return $true
}


Function CMDUpgrade {
    param(
        [String]$ClangbuilderRoot,
        [String]$Pkglocksdir,
        [Switch]$Default
    )
    $pkgtable = @{ }
    Get-ChildItem -Path "$Pkglocksdir/*.json" | ForEach-Object {
        $obj = Get-Content -Path $_.FullName -ErrorAction SilentlyContinue | ConvertFrom-Json  -ErrorAction SilentlyContinue
        if ( $null -eq $obj -or ( $null -eq $obj.version) ) {
            Write-Host -ForegroundColor Red "Invalid file locks: $($_.FullName)"
            return
        }
        $xname = $_.BaseName
        if (!(Test-Path "$ClangbuilderRoot/ports/$xname.json")) {
            if ($Default) {
                Write-Host -ForegroundColor Yellow "remove unported package: $xname"
                CMDUninstall -ClangbuilderRoot $ClangbuilderRoot -Name $xname
                return $true
            }
        }
        $pkgtable["$xname"] = $obj.version
        CMDInstall -ClangbuilderRoot $ClangbuilderRoot -Name $xname -Pkglocksdir $Pkglocksdir | Out-Null
    }

    if ($Default) {
        $devcore = Get-Content "$ClangbuilderRoot/config/devi.json"  -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($null -eq $devcore.core) {
            Write-Host -ForegroundColor Red "devi missing default core package config, file: $ClangbuilderRoot/config/devi.json"
            return $false
        }
        foreach ($t in $devcore.core) {
            if (!$pkgtable.ContainsKey($t)) {
                CMDInstall -ClangbuilderRoot $ClangbuilderRoot -Name $t -Pkglocksdir $Pkglocksdir | Out-Null
            }
        }
    }
    return $true
}

if ($args.Count -eq 0) {
    PrintUsage
    exit 0
}

#$env:PATH.Split(";")

$subcmd = $args[0]
$Pkgroot = "$ClangbuilderRoot/bin/pkgs"
$Pkglocksdir = "$Pkgroot/.locks"
$MutexName = "Clangbuild.Devi.Lock"

if (!(Test-Path $Pkgroot)) {
    mkdir  $Pkgroot
}
if (!(Test-Path $Pkglocksdir)) {
    mkdir  $Pkglocksdir
}
switch ($subcmd) {
    "list" {
        CMDList -Pkglocksdir $Pkglocksdir
    }
    "search" {
        if ($args.Count -ge 2) {
            for ($i = 1; $i -lt $args.Count; $i++) {
                $XPort = $args[$i]
                CMDSearchOne -Root $ClangbuilderRoot -Port $XPort
            }
        }
        else {
            CMDSearch -Root $ClangbuilderRoot
        }
    }
    "install" {
        if ($args.Count -lt 2) {
            Write-Host -ForegroundColor Red "devi install missing argument, example: devi install cmake"
            exit 1
        }

        $pkgname = $args[1]
        $mtx = New-Object System.Threading.Mutex($false, "Clangbuild.Devi.Lock")
        $mtxresult = $mtx.WaitOne(1000)
        if ($mtxresult -eq $false) {
            Write-Host -ForegroundColor Red "devi is running."
            exit 1
        }
        if (!(CMDInstall -ClangbuilderRoot $ClangbuilderRoot -Name $pkgname -Pkglocksdir $Pkglocksdir )) {
            $mtx.ReleaseMutex()
            exit 1
        }
        $mtx.ReleaseMutex()
    }
    "uninstall" {
        if ($args.Count -lt 2) {
            Write-Host -ForegroundColor Red "devi uninstall missing argument, example: devi uninstall putty"
            exit 1
        }

        $pkgname = $args[1]
        $mtx = New-Object System.Threading.Mutex($false, $MutexName)
        $mtxresult = $mtx.WaitOne(1000)
        if ($mtxresult -eq $false) {
            Write-Host -ForegroundColor Red "devi is running."
            exit 1
        }
        if (!(CMDUninstall -ClangbuilderRoot $ClangbuilderRoot -Name $pkgname )) {
            $mtx.ReleaseMutex()
            exit 1
        }
        $mtx.ReleaseMutex()
    }
    "upgrade" {
        if (!(Test-Path "$ClangbuilderRoot/bin/pkgs")) {
            mkdir  "$ClangbuilderRoot/bin/pkgs"
        }
        if (!(Test-Path "$ClangbuilderRoot/bin/pkgs/.locks")) {
            mkdir  "$ClangbuilderRoot/bin/pkgs/.locks"
        }
        $ret = $false
        $mtx = New-Object System.Threading.Mutex($false, $MutexName)
        $mtxresult = $mtx.WaitOne(1000)
        if ($mtxresult -eq $false) {
            Write-Host -ForegroundColor Red "devi is running."
            exit 1
        }
        if ($args.Count -gt 1 -and $args[1] -eq "--default") {
            Write-Host "devi: Use upgrade --default, will install devi.json#core."
            $ret = CMDUpgrade -ClangbuilderRoot  $ClangbuilderRoot -Pkglocksdir $Pkglocksdir  -Default
        }
        else {
            $ret = CMDUpgrade -ClangbuilderRoot  $ClangbuilderRoot -Pkglocksdir $Pkglocksdir
        }
        if ($ret -eq $false) {
            $mtx.ReleaseMutex()
            exit 1
        }
        $mtx.ReleaseMutex()
        Write-Host "Update package completed."
    }
    "version" {
        Write-Host "devi: 1.0"
    }
    "help" {
        PrintUsage
        exit 0
    }
    "--help" {
        PrintUsage
        exit 0
    }
    Default {
        Write-Host -ForegroundColor Red "unsupported command '$subcmd' your can run devi help"
        exit 1
    }
}