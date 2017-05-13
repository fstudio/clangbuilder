#!/usr/bin/env poewershell
#initialize clangbuilder lldb environment

Function Global:Get-Pyhome {
    param(
        [String]$Arch
    )
    $PyCurrent = "3.7", "3.6", "3.5"
    $IsWin64 = [System.Environment]::Is64BitOperatingSystem
    foreach ($s in $PyCurrent) {
        if ($IsWin64 -and ($Arch -eq "x86")) {
            $PythonRegKey = "HKCU:\SOFTWARE\Python\PythonCore\$s-32\InstallPath"    
        }
        else {
            $PythonRegKey = "HKCU:\SOFTWARE\Python\PythonCore\$s\InstallPath"
        }
        if (Test-Path $PythonRegKey) {
            return (Get-ItemProperty $PythonRegKey).'(default)'
        }
    }
    return $null
}
