#!/usr/bin/env pwsh
# GetLLVM

param(
    [Switch]$LLDB,
    [ValidateSet("Mainline", "Stable")]
    [String]$Branch = "Mainline"
)

."$PSScriptRoot\PreInitialize.ps1" # load clangbuilder root

Import-Module -Name "$ClangbuilderRoot\modules\Utils"

$llvmobj = Get-Content -Path "$ClangbuilderRoot/config/llvm.json" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue

if ($null -eq $llvmobj) {
    Write-Host -ForegroundColor Red "LLVM obj resolve error"
    exit 1
}

$outdir = $ClangbuilderRoot + "\out"

Function GetLLVMONE {
    param(
        [String]$Url,
        [String]$CWD,
        [String]$OldName,
        [String]$NewName
    )
    # download
    # unpack
    # move
}

if ($Branch -eq "Release") {
    # download from released page
    $items = $llvmobj.Items
    $version = $llvmobj.Release
    $urlprefix = $llvmobj.Download
    $reloutdir = $outdir + "\rel"
    if (!(Test-Path $reloutdir)) {
        New-Item -ItemType Directory -Path $reloutdir | Out-Null
    }
    $lock = Get-Content -Path "$reloutdir\release.lock.json" -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    if (!null -ne $lock -and ($lock.Version -eq $version)) {
        Write-Host -ForegroundColor Yellow "Found release.lock.json. use cache. If you not want use it, please remove it."
        exit 0
    }
    foreach ($i in $items) {
        # download and tar -xvf
        $itemval = $i.Split(":")
        $name = $itemval[0]
        $NewName = $itemval[1]
        $url = "$urlprefix/$version/$name-$version.src.tar.xz"
        GetLLVMONE -Url $url -CWD $reloutdir -OldName "$name-$version.src" -NewName "$NewName"
    }
    return 0
}


$llvmurl = $llvmobj.Url

if ($null -eq $llvmurl) {
    Write-Host -ForegroundColor Red "Unable resolve llvm url"
    exit 1
}

$Gitrepodir = "mainline"
$GitBranch = "master"
[System.Text.StringBuilder]$CommandSb = "clone "
[void]$CommandSb.Append($llvmurl)
[void]$CommandSb.Append(" --depth=1") # clone url --depth=1

if ($Branch -eq "Stable") {
    $Gitrepodir = $llvmobj.Stable # such as release_80
    $GitBranch = $llvmobj.Stable
    [void]$CommandSb.Append(" --single-branch --branch")
    [void]$CommandSb.Append($llvmobj.Stable)
}

if ($null -eq $Gitrepodir) {
    Write-Host -ForegroundColor Red "Unable resolve llvm branch name"
    exit 1
}

$llvmrepodir = "$outdir\$Gitrepodir"
if (Test-Path $llvmrepodir) {
    $exitcode = ProcessExec -FilePath "git" -Arguments "checkout ." -WorkingDirectory $llvmrepodir
    if ($exitcode -ne 0) {
        Write-Host -ForegroundColor Red "git pull --rebase exitcode $exitcode"
    }
    exit $exitcode
    $exitcode = ProcessExec -FilePath "git" -Arguments "pull origin $GitBranch --rebase" -WorkingDirectory $llvmrepodir
    if ($exitcode -ne 0) {
        Write-Host -ForegroundColor Red "git pull --rebase exitcode $exitcode"
    }
    exit $exitcode
}


$arguments = $CommandSb.ToString()
$exitcode = ProcessExec -FilePath "git" -Arguments $arguments
if ($exitcode -eq 0) {
    Write-Host -ForegroundColor Red "git clone $llvmurl exitcode $exitcode"
}
exit $exitcode