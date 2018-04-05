param(
    [Switch]$LLDB
)

."$PSScriptRoot\ProfileEnv.ps1"

#$MainURL="https://releases.llvm.org/6.0.0/llvm-6.0.0.src.tar.xz"

Function DownloadFile {
    param(
        [String]$Version,
        [String]$Name
    )
    $UserAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome 
    Write-Host "Download $Name-$Version"
    try {
        Invoke-WebRequest -Uri "https://releases.llvm.org/$Version/$Name-$Version.src.tar.xz" -OutFile "$Name.tar.xz" -UserAgent $UserAgent -UseBasicParsing
    }
    catch {
        Write-Host -ForegroundColor Red "$_"
    }
}

Function UnpackFile {
    param(
        [String]$File,
        [String]$Path,
        [String]$OldName,
        [String]$Name
    )
    if (!(Test-Path $Path)) {
        New-Item -Force -ItemType Directory $Path
    }
    # cmake -E tar -xvf file.tar.gz
    $process = Start-Process -FilePath "cmake" -ArgumentList "-E tar -xvf `"$File`"" -WorkingDirectory "$Path" -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Rename-Item -Path "$Path\$OldName" -NewName "$Name"
    }
    else {
        Write-Host -ForegroundColor Red "tar exit: $($process.ExitCode)"
    }
}

Push-Location $PWD

if (!(Test-Path "$ClangbuilderRoot/out/rel")) {
    New-Item -ItemType Directory -Force -Path "$ClangbuilderRoot/out/rel"
}

Set-Location "$ClangbuilderRoot/out/rel"

$revobj = Get-Content -Path "$ClangbuilderRoot/config/revision.json" |ConvertFrom-Json
$release = $revobj.Release

if (Test-Path "$PWD/release.lock.json"  ) {
    $freeze = Get-Content -Path "$PWD/release.lock.json" |ConvertFrom-Json
    if ($freeze.Version -eq $release) {
        Write-Host "Use llvm download cache"
        Pop-Location
        return ;
    }
    else {
        Remove-Item -Force "*.tar.gz"|Out-Null
    }
}

if (Test-Path "$PWD\llvm") {
    Remove-Item -Force -Recurse "$PWD\llvm"
}

Write-Host "LLVM release: $release"

DownloadFile -Version $release -Name "llvm"
DownloadFile -Version $release -Name "cfe"
DownloadFile -Version $release -Name "lld"
DownloadFile -Version $release -Name "compiler-rt"
DownloadFile -Version $release -Name "libcxx"
DownloadFile -Version $release -Name "clang-tools-extra"

if ($LLDB) {
    DownloadFile -Version $release -Name "lldb"
}

UnpackFile -File "$PWD\llvm.tar.xz" -Path "." -OldName "llvm-$release.src" -Name "llvm"
UnpackFile -File "$PWD\cfe.tar.xz" -Path "llvm\tools" -OldName "cfe-$release.src" -Name "clang"
UnpackFile -File "$PWD\clang-tools-extra.tar.xz" -Path "llvm\tools\clang\tools" -OldName "clang-tools-extra-$release.src" -Name "extra"
UnpackFile -File "$PWD\lld.tar.xz" -Path "llvm\tools" -OldName "lld-$release.src" -Name "lld"
UnpackFile -File "$PWD\compiler-rt.tar.xz" -Path "llvm\projects" -OldName "compiler-rt-$release.src" -Name "compiler-rt"
UnpackFile -File "$PWD\libcxx.tar.xz" -Path "llvm\projects" -OldName "libcxx-$release.src" -Name "libcxx"

if ($LLDB) {
    UnpackFile -File "$PWD\lldb.tar.xz" -Path "llvm\tools" -OldName "lldb-$release.src" -Name "lldb"
}

$vercache = @{}
$vercache["Version"] = $release
$vercache["LLDB"] = $LLDB.IsPresent
ConvertTo-Json -InputObject $vercache|Out-File -Encoding utf8 -FilePath "$PWD\release.lock.json"

Pop-Location