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
        [String]$Devlockfile
    )
    $obj = Get-Content -Path $Devlockfile -ErrorAction SilentlyContinue |ConvertFrom-Json  -ErrorAction SilentlyContinue 
    if ($obj -eq $null) {
        Write-Host -ForegroundColor Red "Not found valid installed tools."
        return 
    }
    Write-Host -ForegroundColor Green "devinstall tools, found installed tools:"
    Get-Member -InputObject $obj -MemberType NoteProperty|ForEach-Object {
        $_.Name.PadRight(20) + $obj."$($_.Name)"
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

Function DevInstallOne {
    param(
        [String]$Root,
        [String]$Name,
        [String]$OVersion
    )
    $devpkg = Get-Content "$Root/ports/$Name.json"  -ErrorAction SilentlyContinue |ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($devpkg -eq $null) {
        Write-Host -ForegroundColor Red "`'$Name`' not yet ported."
        return $OVersion
    }
    if ($devpkg.version -eq $null) {
        Write-Host -ForegroundColor Red "`'$Name`' port config invalid."
        return $OVersion
    }
    if ($OVersion -eq $devpkg.version) {
        Write-Host -ForegroundColor Yellow "devinstall: $Name already install. version: $OVersion"
        return $OVersion
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
        return $OVersion
    }
    $ext = $devpkg.extension
    $pkgfile = "$Root\bin\pkgs\$Name.$ext"
    $newdir = "$Root\bin\pkgs\$Name"
    $ret = Devdownload -Uri $besturl -Path "$pkgfile"
    if ($ret -eq $false) {
        return $OVersion
    }
    try {
        if ((Test-Path "$Root\bin\pkgs\$Name")) {
            Move-Item -Force "$Root\bin\pkgs\$Name" "$Root\bin\pkgs\$Name.$PID"
        }
        Switch ($ext) {
            "zip" {
                Expand-Archive -Path $pkgfile -DestinationPath $newdir
                Initialize-ZipArchive -Path $newdir
            } 
            "msi" {
                $ret = Expand-Msi -Path $pkgfile -DestinationPath  $newdir
                if ($ret -eq 0) {
                    Initialize-MsiArchive -Path $newdir
                }
            } 
            "exe" {
                if (!(Test-Path $newdir)) {
                    mkdir $newdir
                }
                Copy-Item -Path $pkgfile -Destination $newdir -Force
            }
        }
    }
    catch {
        if (!(Test-Path "$Root\bin\pkgs\$Name" -and (Test-Path "$Root\bin\pkgs\$Name.$PID"))) {
            Move-Item -Force "$Root\bin\pkgs\$Name.$PID" "$Root\bin\pkgs\$Name"
        }
        if ((Test-Path "$Root\bin\pkgs\$Name.$PID")) {
            #Move-Item -Force "$Root\bin\pkgs\$Name" "$Root\bin\pkgs\$Name.$PID"
            Remove-Item -Force "$Root\bin\pkgs\$Name.$PID"
        }
        return $version
    }
    if ((Test-Path "$Root\bin\pkgs\$Name.$PID")) {
        #Move-Item -Force "$Root\bin\pkgs\$Name" "$Root\bin\pkgs\$Name.$PID"
        Remove-Item -Force "$Root\bin\pkgs\$Name.$PID"
    }
    Remove-Item $pkgfile
    Write-Host -ForegroundColor Green "install $Name success, version: $($devpkg.version)"
    return $devpkg.version
}

Function Devinstalldefault {
    param(
        [String]$Root
    )
    $sstable = @{}
    $devcore = Get-Content "$Root/config/devinstall.json"  -ErrorAction SilentlyContinue |ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($devcore.core -eq $null) {
        Write-Host -ForegroundColor Red "devinstall missing default core tools config, file: $Root/config/devinstall.json"
        return $false
    }
    $Devlockfile = $Root + "/bin/pkgs/devlocks.json"
    $obj = Get-Content $Devlockfile  -ErrorAction SilentlyContinue |ConvertFrom-Json -ErrorAction SilentlyContinue 
    if ($obj -ne $null) {
        $mb = Get-Member -InputObject $obj -MemberType NoteProperty
        if ($mb.Count -ne $null) {
            foreach ($i in $mb) {
                $name = $i.Name
                $version = $obj."$name"
                $ver = DevInstallOne -Root $Root -Name $name -OVersion $version
                if ($ver -ne $null) {
                    Add-Member -InputObject $obj -Name $name -Value $ver -MemberType NoteProperty -Force
                    $sstable["$name"] = $ver
                }
            }
        }
    }

    foreach ($t in $devcore.core) {
        if (!$sstable.ContainsKey($t)) {
            $ver = DevInstallOne -Root $Root -Name $t -OVersion $null
            if ($ver -ne $null) {
                $sstable["$t"] = $ver
            }
        }
    }
    ConvertTo-Json $sstable |Out-File -Force -FilePath "$Root/bin/pkgs/devlocks.json"
    return $true
}

Function DevInstall {
    param(
        [String]$Root,
        [String]$Name
    )
    if (!(Test-Path "$Root/ports/$Name.json")) {
        Write-Host -ForegroundColor Red "devinstall: $Name not yet ported."
        return $false
    }
    $Devlockfile = $Root + "/bin/pkgs/devlocks.json"
    $obj = Get-Content $Devlockfile  -ErrorAction SilentlyContinue |ConvertFrom-Json -ErrorAction SilentlyContinue
    $ver = DevInstallOne  -Root $Root -Name $Name -OVersion $obj."$Name"
    if ($ver -eq $null) {
        return $false
    }

    Add-Member -InputObject $obj -Name $Name -Value $ver -MemberType NoteProperty -Force
    ConvertTo-Json $obj |Out-File -Force -FilePath "$Root/bin/pkgs/devlocks.json"
    return $true
}

Function Devupgrade {
    param(
        [String]$Root,
        [Switch]$Default
    )
    if ($Default) {
        Write-Host "devinstall: Use upgrade --default, will install devinstall.json#core."
        return Devinstalldefault -Root $Root
    }
    $Devlockfile = $Root + "/bin/pkgs/devlocks.json"
    $obj = Get-Content $Devlockfile  -ErrorAction SilentlyContinue |ConvertFrom-Json -ErrorAction SilentlyContinue 
    if ($obj -eq $null) {
        return Devinstalldefault -Root $Root
    }
    $mb = Get-Member -InputObject $obj -MemberType NoteProperty
    if ($mb.Count -eq $null) {
        return Devinstalldefault -Root $Root
    }
    foreach ($i in $mb) {
        $name = $i.Name
        $version = $obj."$name"
        $ver = DevInstallOne -Root $Root -Name $name -OVersion $version
        if ($ver -ne $null) {
            Add-Member -InputObject $obj -Name $name -Value $ver -MemberType NoteProperty -Force
        }
    }
    ConvertTo-Json $obj |Out-File -Force -FilePath "$Root/bin/pkgs/devlocks.json"
    return $true
}

if ($args.Count -eq 0) {
    PrintUsage
    exit 0
}

$subcmd = $args[0]

switch ($subcmd) {
    "list" {
        ListSubcmd -Devlockfile "$ClangbuilderRoot/bin/pkgs/devlocks.json"
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
        if (!(DevInstall -Root $ClangbuilderRoot -Name $pkgname)) {
            exit 1
        }
    }
    "upgrade" {
        $ret = $false
        if ($args.Count -gt 1 -and $args[1] -eq "--default") {
            $ret = Devupgrade -Root  $ClangbuilderRoot -Default
        }
        else {
            $ret = Devupgrade -Root  $ClangbuilderRoot
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