## Mklauncher
$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot
Import-Module -Name "$ClangbuilderRoot\modules\Devi" # Package Manager
Import-Module -Name "$ClangbuilderRoot\modules\Launcher"
Import-Module -Name "$ClangbuilderRoot\modules\VisualStudio"

$ret = DevinitializeEnv -ClangbuilderRoot $ClangbuilderRoot
if ($ret -ne 0) {
    exit 1
}

$ret = DefaultVisualStudio -ClangbuilderRoot $ClangbuilderRoot # initialize default visual studio
if ($ret -ne 0) {
    Write-Host -ForegroundColor Red "Not found valid installed visual studio."
    exit 1
}


Function Mklauncher {
    param(
        [String]$Name
    )
    if (!(Test-Path "$ClangbuilderRoot\bin\pkgs\.locks\$Name.json")) {
        Write-Host -ForegroundColor Red "$Name not install, your can use devi install it."
        return $false
    }
    if (!(Test-Path "$ClangbuilderRoot\ports\$Name.json")) {
        Write-Host -ForegroundColor Red "$Name not ported"
        return $false
    }
    try {
        $portobj = Get-Content "$ClangbuilderRoot\ports\$Name.json"|ConvertFrom-Json
        if ($null -eq $portobj.launcher) {
            Write-Host -ForegroundColor Red "$Name not support launcher"
            return $false
        }
        [System.Collections.ArrayList]$mlinks = @()
        foreach ($o in $portobj.launcher) {
            $srcfile = "$ClangbuilderRoot\bin\pkgs\$Name\$o"
            $basename = (Get-Item $srcfile).BaseName
            if (!(MakeLauncher -Cbroot $ClangbuilderRoot -Name $basename -Path $srcfile)) {
                return $false
            }
            Write-Host -ForegroundColor Green "link $srcfile to $ClangbuilderRoot/bin/pkgs/.linked/$basename.exe"
            $mlinks.Add("$basename.exe")
        }
        $instmd = Get-Content "$ClangbuilderRoot/bin/pkgs/.locks/$Name.json"  -ErrorAction SilentlyContinue |ConvertFrom-Json -ErrorAction SilentlyContinue
        $obj = @{}
        $obj["version"] = $instmd.version
        if ($null -eq $instmd.links) {
            foreach ($lk in $instmd.links) {
                if (!$mlinks.Contains($lk)) {
                    $mlinks.Add($lk)
                }
            }
        }
        $obj["links"] = $mlinks
        $obj["linked"] = $true
        ConvertTo-Json $obj |Out-File -Force -FilePath "$ClangbuilderRoot/bin/pkgs/.locks/$Name.json"
    }
    catch {
        Write-Host "mklauncher error $_"
    }
    return $true
}

if ($args.Count -eq 0) {
    Write-Host "usage: mklauncher tool ..."
    exit 0
}



for ($i = 0; $i -lt $args.Count; $i++) {
    if (Mklauncher -Name $args[$i]) {
        Write-Host -ForegroundColor Green "create launcher success: $($args[$i])"
    }
    else {
        Write-Host -ForegroundColor Red "create launcher failed: $($args[$i])"
    }
}