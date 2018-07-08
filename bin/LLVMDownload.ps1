param(
    [Switch]$LLDB
)

."$PSScriptRoot\ProfileEnv.ps1"

#$MainURL="https://releases.llvm.org/6.0.0/llvm-6.0.0.src.tar.xz"
Function LLVMGet {
    param(
        [String]$Version,
        [String]$Name,
        [String]$OutFile
    )
    $UserAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome 
    Write-Host "Download $Name-$Version"
    $Filename = "$Name-$Version.src.tar.xz"
    try {
        Invoke-WebRequest -Uri "https://releases.llvm.org/$Version/$Name-$Version.src.tar.xz" -OutFile $Filename -UserAgent $UserAgent -UseBasicParsing
    }
    catch {
        Write-Host -ForegroundColor Red "download $Filename failed: $_"
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

LLVMGet -Version $release -Name "llvm"
LLVMGet -Version $release -Name "cfe"
LLVMGet -Version $release -Name "lld"
LLVMGet -Version $release -Name "compiler-rt"
LLVMGet -Version $release -Name "libcxx"
LLVMGet -Version $release -Name "clang-tools-extra"

if ($LLDB) {
    LLVMGet -Version $release -Name "lldb"
}

UnpackFile -File "$PWD\llvm-$release.src.tar.xz" -Path "." -OldName "llvm-$release.src" -Name "llvm"
UnpackFile -File "$PWD\cfe-$release.src.tar.xz" -Path "llvm\tools" -OldName "cfe-$release.src" -Name "clang"
UnpackFile -File "$PWD\clang-tools-extra-$release.src.tar.xz" -Path "llvm\tools\clang\tools" -OldName "clang-tools-extra-$release.src" -Name "extra"
UnpackFile -File "$PWD\lld-$release.src.tar.xz" -Path "llvm\tools" -OldName "lld-$release.src" -Name "lld"
UnpackFile -File "$PWD\compiler-rt-$release.src.tar.xz" -Path "llvm\projects" -OldName "compiler-rt-$release.src" -Name "compiler-rt"
UnpackFile -File "$PWD\libcxx-$release.src.tar.xz" -Path "llvm\projects" -OldName "libcxx-$release.src" -Name "libcxx"

if ($LLDB) {
    UnpackFile -File "$PWD\lldb.tar.xz" -Path "llvm\tools" -OldName "lldb-$release.src" -Name "lldb"
}

$vercache = @{}
$vercache["Version"] = $release
$vercache["LLDB"] = $LLDB.IsPresent
ConvertTo-Json -InputObject $vercache|Out-File -Encoding utf8 -FilePath "$PWD\release.lock.json"

Pop-Location