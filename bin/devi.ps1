#!/usr/bin/env pwsh
# New devi install engine
Function MakeDirReturnFatat {
    param(
        [String]$Dir
    )
    if (!(Test-Path $Dir)) {
        try {
            New-Item -ItemType Directory -Force $Dir | Out-Null
        }
        catch {
            Write-Host -ForegroundColor Red "unable create dir $Dir failed: $_"
            exit 1
        }
    }
} 

## global values
."$PSScriptRoot\PreInitialize.ps1"
Import-Module -Name "$ClangbuilderRoot\modules\Devi" # Package Manager
Import-Module -Name "$ClangbuilderRoot\modules\Utils"
$LinkedDir = "$ClangbuilderRoot\bin\pkgs\.linked"
MakeDirReturnFatat -Dir $LinkedDir
$LockDir = "$ClangbuilderRoot\bin\pkgs\.locks"
MakeDirReturnFatat -Dir $LockDir
$CleanDir = "$ClangbuilderRoot\bin\pkgs\.temp"
MakeDirReturnFatat -Dir $CleanDir
$SzExe = "$ClangbuilderRoot\bin\pkgs\7z\7z.exe"
# We use installed curl if exists or system curl (Windows 10 >17063)
$curlExe = "$ClangbuilderRoot\bin\pkgs\curl\bin\curl.exe"
$deviUA = "Wget/5.0 (MSVC devi)" # TO Set UA as wget.
$IsWindows64 = [System.Environment]::Is64BitOperatingSystem
$curlCommand = Get-Command -CommandType Application curl -ErrorAction SilentlyContinue
if ($null -ne $curlCommand) {
    $curlExeFallback = $curlCommand[0].Source
}
$MutexName = "Clangbuilder.devi.lock"

Function WinGet {
    param(
        [String]$URL,
        [String]$OutFile
    )
    $TlsArg = "--proto-redir =https"
    if (!$URL.StartsWith("https://")) {
        $TlsArg = ""
    }
    $curlargv = "-A `"$deviUA`" --progress-bar -fS --connect-timeout 15 --retry 3 -o `"$OutFile`" -L $TlsArg $URL"
    if (Test-Path $curlExe) {
        Write-Host "devdownload (curl-devi): $URL"
        $ex = ProcessExec -FilePath $curlExe -Argv $curlargv -WD $PWD
        if ($ex -ne 0) {
            Remove-Item -Force $OutFile -ErrorAction SilentlyContinue
            return $false
        }
        return $true
    }
    elseif ($null -ne $curlExeFallback) {
        Write-Host "devdownload (curl-fallback): $URL"
        $ex = ProcessExec -FilePath $curlExeFallback -Argv $curlargv -WD $PWD
        if ($ex -ne 0) {
            Remove-Item -Force $OutFile -ErrorAction SilentlyContinue
            return $false
        }
        return $true
    }
    Write-Host "devdownload (pwsh wget): $URL ..."
    #$xuri = [uri]$Uri
    try {
        Remove-Item -Force $OutFile -ErrorAction SilentlyContinue
        Invoke-WebRequest -Uri $URL -OutFile $OutFile -UserAgent $deviUA -UseBasicParsing
    }
    catch {
        Write-Host -ForegroundColor Red "download failed: $_"
        Remove-Item -Force $OutFile -ErrorAction SilentlyContinue
        return $false
    }
    return $true
}

Function Usage {
    $Version = Get-Content "$ClangbuilderRoot\version" -ErrorAction SilentlyContinue | ForEach-Object {
        return $_
    }
    if ($null -eq $Version) {
        $Version = "1.0"
    }
    Write-Host "devi $Version portable package manager
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

Function Get-Installed {
    Get-ChildItem -Path "$LockDir/*.json" | ForEach-Object {
        $obj = Get-Content -Path $_.FullName -ErrorAction SilentlyContinue | ConvertFrom-Json  -ErrorAction SilentlyContinue
        if ($null -eq $obj -or ($null -eq $obj.version) ) {
            Write-Host -ForegroundColor Red "Invalid file locks: $($_.FullName)"
            return
        }
        $S = $_.BaseName.PadRight(20) + $obj.version
        Write-Host $S
    }
}


Function Repair-Port {
    param(
        [String]$Name
    )
    Write-Host -ForegroundColor Yellow "Try to repair $Name"
    $obj = Get-Content -Path "$LockDir/$Name.json" -ErrorAction SilentlyContinue | ConvertFrom-Json  -ErrorAction SilentlyContinue
    $pkobj = Get-Content -Path "$ClangbuilderRoot/ports/$Name.json" -ErrorAction SilentlyContinue | ConvertFrom-Json  -ErrorAction SilentlyContinue
    if ($null -eq $obj -or ($null -eq $pkobj)) {
        Write-Host "unable parse $Name.json. please uninstall it and retry install"
        return
    }
    if ($null -ne $pkobj.launcher) {
        foreach ($lnk in $pkobj.launcher) {
            $lnkfile = Get-Item "$ClangbuilderRoot/bin/pkgs/$Name/$lnk" -ErrorAction SilentlyContinue
            if ($null -eq $lnkfile) {
                continue
            }
            $lna = Split-Path -Leaf $lnkfile
            $launcher = "$LinkedDir\$lna"
            if (Test-Path $launcher) {
                Write-Host -ForegroundColor Green "launcher: $launcher exists"
                continue
            }
            Write-Host -ForegroundColor Yellow "Please run mklauncher install $Name"
        }
        return
    }
    foreach ($lnk in $pkobj.links) {
        $lnkfile = Get-Item "$ClangbuilderRoot/bin/pkgs/$Name/$lnk" -ErrorAction SilentlyContinue
        if ($null -eq $lnkfile) {
            continue
        }
        $lna = Split-Path -Leaf $lnkfile
        $symlinkfile = "$LinkedDir\$lna"
        if (Test-Path $symlinkfile) {
            Write-Host -ForegroundColor Green "link: $symlinkfile exists"
            continue
        }
        if (Test-Path "$ClangbuilderRoot/bin/blast.exe" ) {
            &"$ClangbuilderRoot/bin/blast.exe" --link  $lnkfile.FullName "$symlinkfile"
        }
        else {
            $symlinkfile = $symlinkfile.Replace("/", "\")
            cmd /c mklink "$symlinkfile" $lnkfile.FullName ## < Windows 10 need Admin
        }
        if ($LASTEXITCODE -ne 0) {
            throw "failed create symlink: $($lnkfile.FullName)"
        }
        Write-Host -ForegroundColor Green "link $($lnkfile.FullName) to $symlinkfile success."
    }
}

Function Repair-Ports {
    Get-ChildItem -Path "$LockDir/*.json" | ForEach-Object {
        Repair-Port -Name $_.BaseName        
    }
}


# if failed return 1
Function Search-Port {
    param(
        [String]$Name
    )
    $Portfile = "$ClangbuilderRoot/ports/$Name.json"
    $cj = Get-Content "$Portfile"  -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($null -eq $cj) {
        Write-Host -ForegroundColor Red "Port: $Name not found. path: $Portfile"
        return 1
    }
    $xversion = $cj.version
    if ($xversion.Length -gt 20) {
        $xversion = $xversion.Substring(0, 15) + "..."
    }
    $S = $Name.PadRight(20) + $xversion.PadRight(20) + $cj.description
    Write-Host $S
    return 0
}

Function Show-Ports {
    Write-Host -ForegroundColor Green "devi portable package manager, found ports:"
    Get-ChildItem -Path "$ClangbuilderRoot/ports/*.json" | ForEach-Object {
        $cj = Get-Content $_.FullName  -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($null -ne $cj) {
            $xversion = $cj.version
            if ($xversion.Length -gt 20) {
                $xversion = $xversion.Substring(0, 15) + "..."
            }
            $S = $_.BaseName.PadRight(20) + $xversion.PadRight(20) + $cj.description
            Write-Host $S
        }
    }
}

# install uninstall
Function Uninstall-Port {
    param(
        [String]$Name
    )
    $lockfile = "$LockDir/$Name.json"
    if ((Test-Path "$lockfile")) {
        $instmd = Get-Content $lockfile  -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($null -ne $instmd.links) {
            foreach ($link in $instmd.links) {
                if ( ![System.String]::IsNullOrEmpty($link)) {
                    Remove-Item -Force "$LinkedDir/$link" -ErrorAction SilentlyContinue
                }
            }
        }
        Remove-Item $lockfile -Force
    }
    else {
        Write-Host -ForegroundColor Red "Not found $Name in $LockDir"
        Remove-Item -Force -Recurse  "$ClangbuilderRoot/bin/pkgs/$Name"  -ErrorAction SilentlyContinue | Out-Null
        return $false
    }
    Remove-Item -Force -Recurse  "$ClangbuilderRoot/bin/pkgs/$Name"  -ErrorAction SilentlyContinue | Out-Null
    Write-Host -ForegroundColor Yellow "devi: uninstall $Name done."
    return $True
}

Function Install-Port {
    param(
        [String]$Name
    )
    if (!(Test-Path "$ClangbuilderRoot/ports/$Name.json")) {
        Write-Host -ForegroundColor Red "devi: `'$Name`' not yet ported."
        return $false
    }
    $pkobj = Get-Content "$ClangbuilderRoot/ports/$Name.json"  -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ( $null -eq $pkobj) {
        Write-Host -ForegroundColor Red "devi: '$Name' not yet ported."
        return $false
    }
    if ($null -eq $pkobj.version) {
        Write-Host -ForegroundColor Red "devi: '$Name' port config invalid."
        return $false
    }
    $ext = $pkobj.extension
    $AllowedExtensions = "exe", "zip", "msi", "7z"
    if (!$AllowedExtensions.Contains($ext)) {
        Write-Host -ForegroundColor Red "devi: extension '$ext' not allowed."
        return $false
    }
  
    if ($pkobj.extension -eq "7z") {
        if (!(Test-Path $SzExe)) {
            Write-Host -ForegroundColor Red "devi: This port '$Name' extension is `'7z`', but 7z not install. Please run devi install 7z."
            return $false
        }
    }
    $oldtable = Get-Content "$LockDir/$Name.json"  -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    $pkversion = $pkobj.version
    if ($null -ne $oldtable -and $oldtable.version -eq $pkversion) {
        Write-Host -ForegroundColor Yellow "devi: $Name is up to date. version: $($oldtable.version)"
        return $true
    }
    $xurl = $pkobj.url
    if ($IsWindows64 -and ($null -ne $pkobj.url64)) {
        $xurl = $pkobj.url64
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
    $outfile = "$CleanDir\$Name.$ext"
    $tempinstalldir = "$CleanDir\$Name"
    if (!(WinGet -URL $besturl -OutFile $outfile)) {
        return $false
    }
    ########### unpack file from temp dir
    try {
        Switch ($ext) {
            "zip" {
                Expand-Archive -Path $outfile -DestinationPath $tempinstalldir
                Initialize-ZipArchive -Path $tempinstalldir
            }
            "msi" {
                $ret = Expand-Msi -Path $outfile -DestinationPath  $tempinstalldir
                if ($ret -ne 0) {
                    throw "Expand $outfile failed"
                }
                Initialize-MsiArchive -Path $tempinstalldir
            }
            "exe" {
                New-Item -ItemType Directory -Force -ErrorAction SilentlyContinue $tempinstalldir | Out-Null
                Copy-Item -Path $outfile -Destination $tempinstalldir -Force
            }
            "7z" {
                $ret = ProcessExec -FilePath $SzExe -Argv "e -spf -y `"$outfile`" `"-o$tempinstalldir`""
                if ($ret -ne 0) {
                    throw "decompress $outfile by 7z failed"
                }
                Initialize-ZipArchive -Path $tempinstalldir
            }
        }
    }
    catch {
        Write-Host -ForegroundColor Red "$_"
        Remove-Item -Force -Recurse  $outfile  -ErrorAction SilentlyContinue | Out-Null
        Remove-Item -Force -Recurse  $tempinstalldir  -ErrorAction SilentlyContinue | Out-Null
        return $false
    }
    $packDir = "$ClangbuilderRoot\bin\pkgs\$Name"
    $backupDir = "$packDir.$PID"
    try {
        Rename-Item -Force  -Path $packDir -NewName $backupDir -ErrorAction SilentlyContinue
        Move-Item  -Force  -Path  $tempinstalldir -Destination $packDir
    }
    catch {
        Rename-Item -Force  -Path  $backupDir -NewName $packDir  -ErrorAction SilentlyContinue
        Write-Host "unable apply $Name to $packDir $_"
    }
    finally {
        Remove-Item -Force -Recurse $backupDir -ErrorAction SilentlyContinue
    }

    $versiontable = @{ }
    $versiontable["version"] = $pkversion
    [System.Collections.ArrayList]$mlinks = @()
    if ($null -ne $oldtable.links) {
        [System.Collections.ArrayList]$lav = @()
        if ($null -ne $pkobj.launcher) {
            foreach ($l in $pkobj.launcher) {
                $lna = Split-Path -Leaf $l
                $lav.Add($lna) | Out-Null
            }
        }
        foreach ($olink in $oldtable.links) {
            if ($lav.Contains($olink)) {
                Write-Host -ForegroundColor Green "Keep launcher: $olink, you can run mklauncher rebuild it."
                $mlinks.Add($olink) | Out-Null
                continue
            }
            if (![System.String]::IsNullOrEmpty($olink)) {
                Remove-Item -Force -Recurse "$LinkedDir/$olink" -ErrorAction SilentlyContinue
            }
        }
    }

    if ($null -ne $pkobj.links ) {
        try {
            foreach ($lnfile in $pkobj.links) {
                $item = Get-Item "$packDir/$lnfile"
                $symlinkfile = Join-Path -Path $LinkedDir -ChildPath $item.Name
                Remove-Item -Force $symlinkfile -ErrorAction SilentlyContinue
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
                [void]$mlinks.Add($item.Name)
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
    if ($null -ne $pkobj.mount) {
        $versiontable["mount"] = $pkobj.mount
    }
    ConvertTo-Json $versiontable | Out-File -Force -FilePath "$LockDir/$Name.json"
    Write-Host -ForegroundColor Green "devi: install $Name success, version: $pkversion"
    return $true
}


# Update ports
Function Update-Ports {
    param(
        [Switch]$Default
    )
    $pkgtable = @{ }
    Get-ChildItem -Path "$LockDir/*.json" | ForEach-Object {
        $obj = Get-Content -Path $_.FullName -ErrorAction SilentlyContinue | ConvertFrom-Json  -ErrorAction SilentlyContinue
        if ( $null -eq $obj -or ( $null -eq $obj.version) ) {
            Write-Host -ForegroundColor Red "Invalid file locks: $($_.FullName)"
            return $false
        }
        $xname = $_.BaseName
        if (!(Test-Path "$ClangbuilderRoot/ports/$xname.json")) {
            if ($Default) {
                Write-Host -ForegroundColor Yellow "remove deprecated package: $xname"
                Uninstall-Port $xname
                return $true
            }
        }
        $pkgtable["$xname"] = $obj.version
        Install-Port -Name $xname Out-Null
    }

    if ($Default) {
        $devcore = Get-Content "$ClangbuilderRoot/config/devi.json"  -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
        if ($null -eq $devcore.core) {
            Write-Host -ForegroundColor Red "devi default ports config missing, file: $ClangbuilderRoot/config/devi.json"
            return $false
        }
        foreach ($n in $devcore.core) {
            if (!$pkgtable.ContainsKey($n)) {
                Install-Port -ClangbuilderRoot $ClangbuilderRoot -Name $n | Out-Null
            }
        }
    }
    return $true
}

if ($args.Count -eq 0) {
    Usage
    exit 1
}

$subcmd = $args[0]



if ($subcmd -eq "list" -or $subcmd -eq "--list" -or $subcmd -eq "-l") {
    Get-Installed
    ## get installed packages
    exit 0
}

if ($subcmd -eq "search" -or $subcmd -eq "--search" -or $subcmd -eq "-s") {
    if ($args.Count -eq 1) {
        Show-Ports
        exit 0
    }
    [int]$ret = 0
    for ($i = 1; $i -lt $args.Count; $i++) {
        $ret2 = Search-Port -Name $args[$i]
        if ($ret2 -ne 0) {
            $ret = $ret2
        }
    }
    exit $ret
}

$uninstallTable = "uninstall", "--uninstall", "remove", "--remove", "-r"
if ($uninstallTable.Contains($subcmd)) {
    if ($args.Count -lt 2) {
        Write-Host -ForegroundColor Red "devi uninstall missing argument`nexample: devi uninstall putty"
        exit 1
    }
    $mtx = New-Object System.Threading.Mutex($false, $MutexName)
    $mtxresult = $mtx.WaitOne(1000)
    if ($mtxresult -eq $false) {
        Write-Host -ForegroundColor Red "Another devi process is running, please try again later."
        exit 1
    }
    for ($i = 1; $i -lt $args.Count; $i++) {
        if (!(Uninstall-Port -Name $args[$i])) {
            $mtx.ReleaseMutex()
            exit 1
        }
    }
    $mtx.ReleaseMutex()
    exit 0
}

if ($subcmd -eq "repair") {
    Repair-Ports
    exit 0
}

if ($subcmd -eq "install" -or $subcmd -eq "--install" -or $subcmd -eq "-i") {
    if ($args.Count -lt 2) {
        Write-Host -ForegroundColor Red "devi install missing argument`nexample: devi install cmake"
        exit 1
    }
    $mtx = New-Object System.Threading.Mutex($false, $MutexName)
    $mtxresult = $mtx.WaitOne(1000)
    if ($mtxresult -eq $false) {
        Write-Host -ForegroundColor Red "Another devi process is running, please try again later."
        exit 1
    }
    for ($i = 1; $i -lt $args.Count; $i++) {
        if (!(Install-Port -Name $args[$i])) {
            $mtx.ReleaseMutex()
            exit 1
        }
    }
    $mtx.ReleaseMutex()
    exit 0
}

$upgradeTable = "upgrade", "--upgrade", "-U"
if ($upgradeTable.Contains($subcmd)) {
    $ret = $false
    $mtx = New-Object System.Threading.Mutex($false, $MutexName)
    $mtxresult = $mtx.WaitOne(1000)
    if ($mtxresult -eq $false) {
        Write-Host -ForegroundColor Red "Another devi process is running, please try again later."
        exit 1
    }
    if ($args.Count -gt 1 -and $args[1] -eq "--default") {
        Write-Host "devi: Use upgrade --default, will install devi.json#core."
        $ret = Update-Ports -Default
    }
    else {
        $ret = Update-Ports
    }
    if ($ret -eq $false) {
        $mtx.ReleaseMutex()
        exit 1
    }
    $mtx.ReleaseMutex()
    Write-Host "Update package completed."
    exit 0
}

$versionTable = "-v", "--version", "version"
if ($versionTable.Contains($subcmd)) {
    Get-Content "$ClangbuilderRoot\version" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "devi $_"
        exit 0
    }
    Write-Host "devi 1.0"
    exit 0
}

$helpTable = "-h", "-?", "/?", "--help", "help"
if ($helpTable.Contains($subcmd)) {
    Usage
    exit 0
}

Write-Host -ForegroundColor Red "Bad command 'devi $subcmd'`nPlease run devi --help see usage"
exit 1