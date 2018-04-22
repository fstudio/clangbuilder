#!/usr/bin/env pwsh
# Devinstall tools

."$PSScriptRoot\ProfileEnv.ps1"
Import-Module -Name "$ClangbuilderRoot\modules\Devinstall" # Package Manager
Import-Module -Name  "$ClangbuilderRoot\modules\Utils"

Function PrintUsage {
    Write-Host "DevInstall utilies 1.0
Usage: devinstall cmd args
       list        list installed tools
       search      search ported tools
       install     install tools
       upgrade     upgrade tools
       version     print devinstall version and exit
       help        print help message
"
}
Function ListSubcmd {
    param(
        [String]$Pkglocksdir
    )
    Get-ChildItem -Path "$Pkglocksdir/*.json"|ForEach-Object {
        $obj = Get-Content -Path $_.FullName -ErrorAction SilentlyContinue |ConvertFrom-Json  -ErrorAction SilentlyContinue 
        if ($obj -eq $null -or $obj.version -eq $null) {
            Write-Host -ForegroundColor Red "Invalid file locks: $($_.FullName)"
            return 
        }
        $_.BaseName.PadRight(20) + $obj.version
    }
}

# search
Function SearchSubcmd {
    param(
        [String]$Root
    )
    Write-Host -ForegroundColor Green "devinstall tools, found ports:"
    Get-ChildItem -Path "$Root/ports/*.json" |ForEach-Object {
        $cj = Get-Content $_.FullName  -ErrorAction SilentlyContinue |ConvertFrom-Json -ErrorAction SilentlyContinue 
        if ($cj -ne $null) {
            "$($_.BaseName)".PadRight(20) + "$($cj.version)".PadRight(20) + $cj.description
        }
    }
}


Function DevbaseUninstall {
    param(
        [String]$ClangbuilderRoot,
        [String]$Name
    )
    $lockfile = "$ClangbuilderRoot/bin/pkgs/.locks/$Name.json"
    if (!(Test-Path "$Pkglocksdir/$Name.json")) {
        Write-Host -ForegroundColor Red "not found $Name in $Pkglocksdir"
    }
    else {
        $instmd = Get-Content $lockfile  -ErrorAction SilentlyContinue |ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($instmd.links -ne $null) {
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
        Remove-Item -Force -Recurse  $pkgdir  -ErrorAction SilentlyContinue |Out-Null
    }
    Write-Host -ForegroundColor Yellow "devinstall: uninstall $Name done."
}

Function DevbaseInstall {
    param(
        [String]$ClangbuilderRoot,
        [String]$Pkglocksdir,
        [String]$Name
    )
    if (!(Test-Path "$ClangbuilderRoot/ports/$Name.json")) {
        Write-Host -ForegroundColor Red "devinstall: $Name not yet ported."
        return $false
    }
    $devpkg = Get-Content "$ClangbuilderRoot/ports/$Name.json"  -ErrorAction SilentlyContinue |ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($devpkg -eq $null) {
        Write-Host -ForegroundColor Red "`'$Name`' not yet ported."
        return $false
    }
    if ($devpkg.version -eq $null) {
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

    $oldtable = Get-Content "$Pkglocksdir/$Name.json"  -ErrorAction SilentlyContinue |ConvertFrom-Json -ErrorAction SilentlyContinue
    $pkversion = $devpkg.version
    if ($oldtable -ne $null -and $oldtable.version -eq $pkversion) {
        Write-Host -ForegroundColor Yellow "devinstall: $Name is up to date. version: $($oldtable.version)"
        return $true
    }
    $xurl = $devpkg.url
    if ([System.Environment]::Is64BitOperatingSystem -and $devpkg.url64 -ne $null) {
        $xurl = $devpkg.url64
    }
    $besturl = $null
    if ($xurl -is [array]) {
        $besturl = Test-BestSourcesURL -Urls $xurl
    }
    else {
        $besturl = $xurl
    }
    if ($besturl -eq $null) {
        return $null
    }

    $pkgfile = "$ClangbuilderRoot\bin\pkgs\$Name.$ext"
    $installdir = "$ClangbuilderRoot\bin\pkgs\$Name"
    $tempdir = "$installdir.$PID"
    $ret = Devdownload -Uri $besturl -Path "$pkgfile"
    if ($ret -eq $false) {
        return $null
    }
    try {
        if ((Test-Path $installdir)) {
            Move-Item -Force  $installdir $tempdir -ErrorAction SilentlyContinue |Out-Null
        }
        Switch ($ext) {
            "zip" {
                Expand-Archive -Path $pkgfile -DestinationPath $installdir
                Initialize-ZipArchive -Path $installdir
            } 
            "msi" {
                $ret = Expand-Msi -Path $pkgfile -DestinationPath  $installdir
                if ($ret -eq 0) {
                    Initialize-MsiArchive -Path $installdir
                }
            } 
            "exe" {
                if (!(Test-Path $installdir)) {
                    mkdir $installdir|Out-Null
                }
                Copy-Item -Path $pkgfile -Destination $installdir -Force
            }
            "7z" {
                $ret = ProcessExec -FilePath $sevenzipbin -Arguments "e -spf -y `"$pkgfile`" `"-o$installdir`""
                if ($ret -ne 0) {
                    throw "decompress $pkgfile by 7z failed"
                }
                Initialize-ZipArchive -Path $installdir
            }
        }
    }
    catch {
        if (!(Test-Path $installdir) -and (Test-Path $tempdir)) {
            Move-Item -Force $tempdir $installdir -ErrorAction SilentlyContinue |Out-Null
        }
        if (Test-Path $tempdir) {
            Remove-Item -Force -Recurse  $tempdir  -ErrorAction SilentlyContinue |Out-Null
        }
        return $false
    }

    $versiontable = @{}
    $versiontable["version"] = $pkversion
    if ($devpkg.links -ne $null) {
        if (!(Test-Path "$ClangbuilderRoot/bin/pkgs/.linked")) {
            mkdir "$ClangbuilderRoot/bin/pkgs/.linked"|Out-Null
        }
        try {
            [System.Collections.ArrayList]$mlinks = @()
            foreach ($i in $devpkg.links) {
                $srcfile = "$installdir/$i"
                $item = Get-Item $srcfile
                $symlinkfile = "$ClangbuilderRoot/bin/pkgs/.linked/" + $item.Name
                if (Test-Path $symlinkfile) {
                    Remove-Item -Force -Recurse $symlinkfile
                }
                if(Test-Path "$ClangbuilderRoot/bin/blast.exe" ){
                    &"$ClangbuilderRoot/bin/blast.exe" --link  "$($item.FullName)" "$symlinkfile"
                }else{
                    cmd /c mklink "$symlinkfile" "$($item.FullName)" ## < Windows 10 need Admin
                }
                if ($LASTEXITCODE -ne 0) {
                    throw "failed create symlink: $symlinkfile"
                }
                $mlinks.Add($item.Name)|Out-Null
                Write-Host -ForegroundColor Green "link $($item.FullName) to $symlinkfile success."
            }
            if ($mlinks.Count -gt 0) {
                $versiontable["links"] = $mlinks
            }
            $versiontable["linked"] = $true
        }
        catch {
            Write-Host -ForegroundColor Red "create symbolic link failed: $_"
        }
    }
    ConvertTo-Json $versiontable |Out-File -Force -FilePath "$Pkglocksdir/$Name.json"
    if (Test-Path $tempdir) {
        Remove-Item -Force -Recurse $tempdir  -ErrorAction SilentlyContinue |Out-Null
    }
    Remove-Item $pkgfile -Force -ErrorAction SilentlyContinue |Out-Null ##ignore remove-item return del/null
    Write-Host -ForegroundColor Green "devinstall: install $Name success, version: $pkversion"
    return $true
}


Function Devupgrade {
    param(
        [String]$ClangbuilderRoot,
        [String]$Pkglocksdir,
        [Switch]$Default
    )
    $pkgtable = @{}
    Get-ChildItem -Path "$Pkglocksdir/*.json"|ForEach-Object {
        $obj = Get-Content -Path $_.FullName -ErrorAction SilentlyContinue |ConvertFrom-Json  -ErrorAction SilentlyContinue 
        if ($obj -eq $null -or $obj.version -eq $null) {
            Write-Host -ForegroundColor Red "Invalid file locks: $($_.FullName)"
            return 
        }
        $xname = $_.BaseName
        if (!(Test-Path "$ClangbuilderRoot/ports/$xname.json")) {
            if ($Default) {
                Write-Host -ForegroundColor Yellow "remove unported package: $xname"
                DevbaseUninstall -ClangbuilderRoot $ClangbuilderRoot -Name $xname
                return $true
            }
        }
        $pkgtable["$xname"] = $obj.version
        DevbaseInstall -ClangbuilderRoot $ClangbuilderRoot -Name $xname -Pkglocksdir $Pkglocksdir|Out-Null
    }

    if ($Default) {
        $devcore = Get-Content "$ClangbuilderRoot/config/devinstall.json"  -ErrorAction SilentlyContinue |ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($devcore.core -eq $null) {
            Write-Host -ForegroundColor Red "devinstall missing default core tools config, file: $ClangbuilderRoot/config/devinstall.json"
            return $false
        }
        
        foreach ($t in $devcore.core) {
            if (!$pkgtable.ContainsKey($t)) {
                DevbaseInstall -ClangbuilderRoot $ClangbuilderRoot -Name $t -Pkglocksdir $Pkglocksdir|Out-Null
            }
        }
    }
    return $true
}

if ($args.Count -eq 0) {
    PrintUsage
    exit 0
}

$subcmd = $args[0]
$Pkgroot = "$ClangbuilderRoot/bin/pkgs"
$Pkglocksdir = "$Pkgroot/.locks"

if (!(Test-Path $Pkgroot)) {
    mkdir  $Pkgroot
}
if (!(Test-Path $Pkglocksdir)) {
    mkdir  $Pkglocksdir
}
switch ($subcmd) {
    "list" {
        ListSubcmd -Pkglocksdir $Pkglocksdir
    }
    "search" {
        SearchSubcmd -Root $ClangbuilderRoot
    }
    "install" {
        if ($args.Count -lt 2) {
            Write-Host -ForegroundColor Red "devinstall install missing argument, example: devinstall install cmake"
            exit 1
        }

        $pkgname = $args[1]
        if (!(DevbaseInstall -ClangbuilderRoot $ClangbuilderRoot -Name $pkgname -Pkglocksdir $Pkglocksdir )) {
            exit 1
        }
    }
    "uninstall" {
        if ($args.Count -lt 2) {
            Write-Host -ForegroundColor Red "devinstall uninstall missing argument, example: devinstall uninstall putty"
            exit 1
        }

        $pkgname = $args[1]
        if (!(DevbaseUninstall -ClangbuilderRoot $ClangbuilderRoot -Name $pkgname )) {
            exit 1
        }
    }
    "upgrade" {
        if (!(Test-Path "$ClangbuilderRoot/bin/pkgs")) {
            mkdir  "$ClangbuilderRoot/bin/pkgs"
        }
        if (!(Test-Path "$ClangbuilderRoot/bin/pkgs/.locks")) {
            mkdir  "$ClangbuilderRoot/bin/pkgs/.locks"
        }
        $ret = $false
        if ($args.Count -gt 1 -and $args[1] -eq "--default") {
            Write-Host "devinstall: Use upgrade --default, will install devinstall.json#core."
            $ret = Devupgrade -ClangbuilderRoot  $ClangbuilderRoot -Pkglocksdir $Pkglocksdir  -Default
        }
        else {
            $ret = Devupgrade -ClangbuilderRoot  $ClangbuilderRoot -Pkglocksdir $Pkglocksdir
        }
        if ($ret -eq $false) {
            exit 1
        }
        Write-Host "Update package completed."
    }
    "version" {
        Write-Host "devinstall: 1.0"
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
        Write-Host -ForegroundColor Red "unsupported command '$xcmd' your can run devinstall help -a"
        exit 1
    }
}