#!/usr/bin/env pwsh
# Require Clangbuilder install perl

$ZLIB_VERSION = "1.2.11"
$OPENSSL_VERSION = "1.1.1"
$BROTLI_VERSION = "1.0.5"
$LIBSSH2_VERSION = "1.8.0"


# Filename
$ZLIB_FILENAME = "zlib-${ZLIB_VERSION}"

$ZLIB_URL = "https://github.com/madler/zlib/archive/v${ZLIB_VERSION}.tar.gz"
$OPENSSL_URL = "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz"
$BROTLI_URL = "https://github.com/google/brotli/archive/v${BROTLI_VERSION}.tar.gz"
$LIBSSH2_URL = "https://github.com/libssh2/libssh2/releases/download/libssh2-${LIBSSH2_VERSION}/libssh2-${LIBSSH2_VERSION}.tar.gz"

Write-Verbose $ZLIB_URL $OPENSSL_URL $BROTLI_URL $LIBSSH2_URL

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Global:Subffix = ""
if ($IsDesktop -or $IsWindows) {
    $Global:Subffix = ".exe"
}

Function Findcommand {
    param(
        [String]$Name
    )
    $command = Get-Command -CommandType Application "$Name$($Global:Subffix)" -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        return $null
    }
    return $command.Source
}

Function MkdirAll {
    param(
        [String]$Dir
    )
    try {
        New-Item -ItemType Directory -Force $Dir
    }
    catch {
        Write-Host -ForegroundColor Red "$_"
        return $false
    }
    return $true
}

Function WinGet {
    param(
        [String]$URL,
        [String]$O
    )
    # 
    Write-Host "Download: $O"
    $UserAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
    try {
        Invoke-WebRequest -Uri $URL -OutFile $O -UseBasicParsing -UserAgent $UserAgent

    }
    catch {
        Write-Host -ForegroundColor Red "download $O failed: $_"
        return $false
    }
    return $true
}

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


$Ninjaexe=Findcommand -Name "ninja"
if ($null -eq $Ninjaexe) {
    Write-Host -ForegroundColor Red "Please install ninja."
    return 1
}

Write-Host -ForegroundColor Green "Find cmake install: $Ninjaexe"

$Patchexe=Findcommand -Name "patch"
if($null -eq $Patchexe){
    $Gitexe=Findcommand -Name "git"
    if ($null -eq $Gitexe) {
        Write-Host -ForegroundColor Red "Please install git for windows (or PortableGit)."
        return 1
    }
    $gitinstall=Split-Path -Parent (Split-Path -Parent $gitexe)
    if([String]::IsNullOrEmpty($gitinstall)){
        Write-Host -ForegroundColor Red "Please install git for windows (or PortableGit)."
        return 1
    }
    $patchx=Join-Path $gitinstall "usr/bin/patch.exe"
    if(!(Test-Path $patchx)){
        $xinstall=Split-Path -Parent $gitinstall
        if([String]::IsNullOrEmpty($xinstall)){
            Write-Host -ForegroundColor Red "Please install git for windows (or PortableGit)."
            return 1
        }
        $patchx=Join-Path  $xinstall "usr/bin/patch.exe"
        if(!(Test-Path $patchx)){
            Write-Host -ForegroundColor Red "Please install git for windows (or PortableGit)."
            return 1
        }
    }
    $Patchexe=$pathx
}

Write-Host  -ForegroundColor Green "Found patch install: $Patchexe"

#git dir usr/bin/patch.exe
Function DecompressTar {
    param(
        [String]$File
    )
    $p = Start-Process -FilePath $tarexe -ArgumentList "$decompress $File" -Wait -NoNewWindow -PassThru
    if ($p.ExitCode -ne 0) {
        return $false
    }
    return $true
}

$Prefix = "$PWD/build"

if (!(MkdirAll -Dir $Prefix)) {
    exit 1
}

if (!(WinGet -URL $ZLIB_URL -O "$ZLIB_FILENAME.tar.gz")) {
    exit 1
}

if (!(DecompressTar -File "$ZLIB_FILENAME.tar.gz")) {
    Write-Host -ForegroundColor Red "Decompress $ZLIB_FILENAME.tar.gz failed!"
    exit 1
}
# Apply patch
$ZLIB_PACTH = "$PSScriptRoot/zlib.patch"

Set-Location "$ZLIB_FILENAME"

&"$Pacthexe" -Nbp1 -i $ZLIB_PACTH

Set-Location ".."

if (!(MkdirAll -Dir "zlib_build")) {
    exit 1
}

Set-Location "zlib_build"
cmake -GNinja -DCMAKE_BUILD_TYPE=Release`
-DCMAKE_INSTALL_PREFIX=$Prefix `
    -DSKIP_INSTALL_FILES=ON `
    -DSKIP_BUILD_EXAMPLES=ON `
    -DBUILD_SHARED_LIBS=OFF `
    "../$ZLIB_FILENAME"
## TODO build
ninja all
ninja install


# build zlib static
# build openssl static
# build libssh2 static ?
# build brotli static
# build curl static
# download curl-ca-bundle.crt