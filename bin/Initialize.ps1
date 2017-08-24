#!/usr/bin/env poewershell
#initialize clangbuilder environment common

if ($PSVersionTable.PSVersion.Major -lt 3) {
    $PSVersionString = $PSVersionTable.PSVersion.Major
    Write-Error "Clangbuilder must run under PowerShell 3.0 or later host environment !"
    Write-Error "Your PowerShell Version:$PSVersionString"
    if ($Host.Name -eq "ConsoleHost") {
        [System.Console]::ReadKey()
    }
    Exit
}

Function Global:Test-AddPathEx {
    param(
        [String]$Path
    )
    if (Test-Path $Path) {
        $env:Path = "$Path;${env:Path}"
    }
}

#$result=Update-Language -Lang 65001 # initialize language
Function Global:Update-Language {
    param(
        [int]$Lang=65001
    )
    $code = @'
[DllImport("Kernel32.dll")]
public static extern bool SetConsoleCP(int wCodePageID);
[DllImport("Kernel32.dll")]
public static extern bool SetConsoleOutputCP(int wCodePageID);

'@
    $wconsole = Add-Type -MemberDefinition $code -Name "WinConsole" -PassThru
    $result=$wconsole::SetConsoleCP($Lang)
    $result=$wconsole::SetConsoleOutputCP($Lang)
}

Function Global:Update-Title {
    param(
        [String]$Title
    )
    $MyTitle = $Host.UI.RawUI.WindowTitle + $Title
    $Host.UI.RawUI.WindowTitle = $MyTitle
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
