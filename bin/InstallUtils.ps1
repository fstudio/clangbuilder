# Powershell Clangbuilder package manger

$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot
$Pkgdir = "$ClangbuilderRoot/bin/pkgs"

Import-Module -Name "$ClangbuilderRoot\modules\NetTLS"
InitializeTLS

Import-Module -Name "$Global:ClangbuilderRoot\modules\PM" # Package Manager

if (!(Test-Path "$Pkgdir")) {
    New-Item -ItemType Directory -Path $Pkgdir -Force |Out-Null
}
if (!(Test-Path "$Pkgdir\packages.lock.json")) {
    "{}"|Out-File -FilePath "$Pkgdir\packages.lock.json"
}

$packages = Get-Content -Path "$ClangbuilderRoot\config\packages.json" |ConvertFrom-Json
$ipkgs = Get-Content -Path "$Pkgdir\packages.lock.json" |ConvertFrom-Json
$pklocation = ""

if (Test-Path "$ClangbuilderRoot\config\pkinit.json") {
    $pkinfo = Get-Content -Path "$ClangbuilderRoot\config\pkinit.json" |ConvertFrom-Json
    $pklocation = $pkinfo.Location
    Write-Host "Your location is $pklocation, we can use mirror"
}
$pkgcaches = @{}

$pkgs = $packages.Packages
foreach ($i in $pkgs) {
    $Name = $i.Name
    if ($i.Version -eq $ipkgs.$Name) {
        $pkgcaches[$Name] = $i.Version
        Write-Host -ForegroundColor Green "$Name $($i.Version) is up to date !"
        continue
    }
    Write-Host "Install new ${Name}: $($i.Version) ..."
    if ((Test-Path "$Pkgdir\$Name")) {
        Rename-Item "$Pkgdir\$Name" "$Pkgdir\$Name.bak"
    }
    $myurl = $null
    if ($pklocation -ne "" -and $null -ne $i.$pklocation) {
        Write-Host "$Name use mirror"
        if ($null -ne $i.$pklocation.URL) {
            $myurl = $i.$pklocation.URL
        }
        elseif ([System.Environment]::Is64BitOperatingSystem) {
            $myurl = $i.$pklocation.X64URL
        }
        else {
            $myurl = $i.$pklocation.X86URL
        }
    }
    if ($myurl -eq $null) {
        if ($null -ne $i.URL) {
            $myurl = $i.URL
        }
        elseif ([System.Environment]::Is64BitOperatingSystem) {
            $myurl = $i.X64URL
        }
        else {
            $myurl = $i.X86URL
        }
    }

    Install-Package -ClangbuilderRoot $ClangbuilderRoot -Name $Name -Uri $myurl -Extension $i.Extension
    if (!(Test-Path "$Pkgdir\$Name")) {
        $pkgcaches[$Name] = $ipkgs.$Name
        if (Test-Path "$Pkgdir\$Name.bak") {
            Move-Item "$Pkgdir\$Name.bak" "$Pkgdir\$Name"
        }
    }
    else {
        if (Test-Path "$Pkgdir\$Name.bak") {
            Remove-Item -Force -Recurse "$Pkgdir\$Name.bak"
        }
        $pkgcaches[$Name] = $i.Version
    }
}

ConvertTo-Json $pkgcaches |Out-File -Force -FilePath "$Pkgdir\packages.lock.json"

Write-Host "Update package completed."
