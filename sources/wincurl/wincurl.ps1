#!/usr/bin/env pwsh
# Require Clangbuilder install perl

param(
    [String]$WD
)

# Import version info
. "$PSScriptRoot/version.ps1"

# thanks https://github.com/curl/curl-for-win

# Filename
$ZLIB_FILENAME = "zlib-${ZLIB_VERSION}"

#$ZLIB_URL = "https://github.com/madler/zlib/archive/v${ZLIB_VERSION}.tar.gz"
$ZLIB_URL = "https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz"
$OPENSSL_URL = "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
$BROTLI_URL = "https://github.com/google/brotli/archive/v${BROTLI_VERSION}.tar.gz"
$LIBSSH2_URL = "https://github.com/libssh2/libssh2/releases/download/libssh2-${LIBSSH2_VERSION}/libssh2-${LIBSSH2_VERSION}.tar.gz"

Write-Host $ZLIB_URL $OPENSSL_URL $BROTLI_URL $LIBSSH2_URL

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Import-Module -Name "$PSScriptRoot/Utility"

$clexe = Get-Command -CommandType Application "cl" -ErrorAction SilentlyContinue
if ($null -eq $clexe) {
    Write-Host -ForegroundColor Red "Please install Visual Studio 2017 or BuildTools (C++) and Initialzie DevEnv"
    exit 1
}

Write-Host "Find cl.exe: $($clexe.Version)"

$tarexe = Findcommand -Name "tar"
$decompress = "-xvf"
if ($null -eq $tarexe) {
    $tarexe = Findcommand -Name "cmake"
    if ($null -eq $tarexe) {
        Write-Host -ForegroundColor Red "Please install tar or cmake."
        exit 1
    }
    $decompress = "-E tar -xvf"
}
Write-Host -ForegroundColor Green "Use $tarexe as tar"

$cmakeexe = Findcommand -Name "cmake"
if ($null -eq $cmakeexe) {
    Write-Host -ForegroundColor Red "Please install cmake."
    return 1
}
Write-Host -ForegroundColor Green "Find cmake install: $cmakeexe"


$Ninjaexe = Findcommand -Name "ninja"
if ($null -eq $Ninjaexe) {
    Write-Host -ForegroundColor Red "Please install ninja."
    return 1
}

Write-Host -ForegroundColor Green "Find cmake install: $Ninjaexe"

$Patchexe = Findcommand -Name "patch"
if ($null -eq $Patchexe) {

    $Gitexe = Findcommand -Name "git"
    if ($null -eq $Gitexe) {
        Write-Host -ForegroundColor Red "Please install git for windows (or PortableGit)."
        return 1
    }
    $gitinstall = Split-Path -Parent (Split-Path -Parent $gitexe)
    if ([String]::IsNullOrEmpty($gitinstall)) {
        Write-Host -ForegroundColor Red "Please install git for windows (or PortableGit)."
        return 1
    }
    $patchx = Join-Path $gitinstall "usr/bin/patch.exe"
    Write-Host "Try to find patch from $patchx"
    if (!(Test-Path $patchx)) {
        $xinstall = Split-Path -Parent $gitinstall
        if ([String]::IsNullOrEmpty($xinstall)) {
            Write-Host -ForegroundColor Red "Please install git for windows (or PortableGit)."
            return 1
        }
        $patchx = Join-Path  $xinstall "usr/bin/patch.exe"
        if (!(Test-Path $patchx)) {
            Write-Host -ForegroundColor Red "Please install git for windows (or PortableGit)."
            return 1
        }
    }
    $Patchexe = $patchx
}

Write-Host  -ForegroundColor Green "Found patch install: $Patchexe"

#git dir usr/bin/patch.exe


if ([String]::IsNullOrEmpty($WD)) {
    $cbroot = Split-Path -Parent (Split-Path -Path $PSScriptRoot)
    $WD = Join-Path $cbroot "out/curl"
}
if (!(MkdirAll -Dir $WD)) {
    exit 1
}

Write-Host -ForegroundColor Cyan "Build curl on windows use"

Set-Location $WD

$Prefix = Join-Path $WD "build"
$CURLPrefix = Join-Path $WD "out"

Write-Host "we will deploy curl to: $CURLPrefix"

if (!(MkdirAll -Dir $Prefix)) {
    exit 1
}

if (!(WinGet -URL $ZLIB_URL -O "$ZLIB_FILENAME.tar.gz")) {
    exit 1
}


if ((Exec -FilePath $tarexe -Argv "$decompress $ZLIB_FILENAME.tar.gz") -ne 0) {
    Write-Host -ForegroundColor Red "Decompress $ZLIB_FILENAME.tar.gz failed!"
    exit 1
}

$ZLIBDIR = Join-Path $PWD $ZLIB_FILENAME
$ZLIBBD = Join-Path $PWD "zlib_build"

Write-Host -ForegroundColor Yellow "Apply zlib.patch ..."
$ZLIB_PACTH = Join-Path $PSScriptRoot "zlib.patch"

$ec = Exec -FilePath $Patchexe -Argv "-Nbp1 -i `"$ZLIB_PACTH`"" -WD $ZLIBDIR
if ($ec -ne 0) {
    Write-Host -ForegroundColor Red "Apply $ZLIB_PACTH failed"
}

if (!(MkdirAll -Dir "zlib_build")) {
    exit 1
}

$cmakeflags = "-GNinja " + `
    "-DCMAKE_BUILD_TYPE=Release " + `
    "`"-DCMAKE_INSTALL_PREFIX=$Prefix`" " + `
    "-DSKIP_INSTALL_FILES=ON " + `
    "-DSKIP_BUILD_EXAMPLES=ON " + `
    "-DBUILD_SHARED_LIBS=OFF `"$ZLIBDIR`""


$ec = Exec -FilePath $cmakeexe -Argv $cmakeflags -WD $ZLIBBD
if ($ec -ne 0) {
    Write-Host -ForegroundColor Red "zlib: create build.ninja error"
    return 1
}

$ec = Exec -FilePath $Ninjaexe -Argv "all" -WD $ZLIBBD
if ($ec -ne 0) {
    Write-Host -ForegroundColor Red "zlib: build error"
    return 1
}

$ec = Exec -FilePath $Ninjaexe -Argv "install" -WD $ZLIBBD
if ($ec -ne 0) {
    Write-Host -ForegroundColor Red "zlib: install error"
    return 1
}

Rename-Item -Path "$Prefix/lib/zlibstatic.lib"   "$Prefix/lib/zlib.lib"  -Force -ErrorAction SilentlyContinue
#Copy-Item -Path "$ZLIBDIR/LICENSE" 

# build zlib static
# build openssl static
# build libssh2 static ?
# build brotli static
# build curl static
# download curl-ca-bundle.crt