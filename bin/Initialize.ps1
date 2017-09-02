#!/usr/bin/env poewershell

Function Global:Test-AddPathEx {
    param(
        [String]$Path
    )
    if (Test-Path $Path) {
        $env:Path = "$Path;${env:Path}"
    }
}

Function Test-IsAdministrator {
    ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
            [Security.Principal.WindowsBuiltInRole] "Administrator")
}


$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot
$HomeDir = $env:HOMEDRIVE + $env:HOMEPATH;
$InitializeFile = "$ClangbuilderRoot/config/initialize.json"

Function Add-AbstractPath {
    param(
        [String]$Dir
    )
    if ($Dir.StartsWith("@")) {
        $FullDir = $ClangbuilderRoot + "\" + $Dir.Substring(1);
    }
    elseif ($Dir.StartsWith("~")) {
        $FullDir = $HomeDir + "\" + $Dir.Substring(1);
    }
    else {
        $FullDir = $Dir;
    }
    Test-AddPathEx -Path $FullDir
}



if (!(Test-Path $InitializeFile)) {
    return 0 ### when not exists initialize.json
}

$InitializeObj = Get-Content -Path $InitializeFile |ConvertFrom-Json

# Window Title
if ($null -ne $InitializeObj.Title) {
    $Host.UI.RawUI.WindowTitle = $InitializeObj.Title
}


# Welcome Message
if ($null -ne $InitializeObj.Welcome) {
    Write-Host $InitializeObj.Welcome
}
# 

if ($null -ne $InitializeObj.PATH) {
    foreach ($Np in $InitializeObj.PATH) {
        Add-AbstractPath -Dir $Np
    }
}
