## Initialize Modules

Function Test-AddPathEx {
    param(
        [String]$Path
    )
    if (Test-Path $Path) {
        $env:PATH = $Path + [System.IO.Path]::PathSeparator + $env:PATH
    }
}

Function Add-AbstractPath {
    param(
        [String]$ClangbuilderRoot,
        [String]$Dir
    )
    if ($Dir.StartsWith("@")) {
        $FullDir = $ClangbuilderRoot + "\" + $Dir.Substring(1);
    }
    elseif ($Dir.StartsWith("~")) {
        $HomeDir = $env:HOMEDRIVE + $env:HOMEPATH;
        $FullDir = $HomeDir + "\" + $Dir.Substring(1);
    }
    else {
        $FullDir = $Dir;
    }
    Test-AddPathEx -Path $FullDir
}


Function InitializeEnv {
    param(
        [String]$ClangbuilderRoot
    )
    if (!$env:PATH.EndsWith( [System.IO.Path]::PathSeparator)) {
        $env:PATH += [System.IO.Path]::PathSeparator
    }
    $env:PATH = $env:PATH + "$ClangbuilderRoot" + [System.IO.Path]::DirectorySeparatorChar + "bin"
    $InitializeFile = "$ClangbuilderRoot/config/initialize.json"
    if (!(Test-Path $InitializeFile)) {
        return
    }
    $InitializeObj = Get-Content -Path $InitializeFile | ConvertFrom-Json
    # Welcome Message
    if ($null -ne $InitializeObj.Welcome) {
        Write-Host $InitializeObj.Welcome
    }
    # Other
    if ($null -ne $InitializeObj.PATH) {
        foreach ($Np in $InitializeObj.PATH) {
            Add-AbstractPath -Dir $Np
        }
    }
}

Function InitializeExtranl {
    param(
        [ValidateSet("x86", "x64", "ARM", "ARM64")]
        [String]$Arch = "x64",
        [String]$ClangbuilderRoot
    )
    $ExtranlDir = "$ClangbuilderRoot\bin\external"
    if (Test-Path "$ExtranlDir\include") {
        $env:INCLUDE = $env:INCLUDE + ";$ExtranlDir\include"
    }
    if (Test-Path "$ExtranlDir\lib\$Arch") {
        $env:LIB = $env:LIB + ";$ExtranlDir\lib\$Arch"
    }
    if (Test-Path "$ExtranlDir\bin\$Arch") {
        $env:PATH = $env:PATH + ";$ExtranlDir\bin\$Arch"
    }
    elseif (Test-Path "$ExtranlDir\bin") {
        $env:PATH = $env:PATH + ";$ExtranlDir\bin\$Arch"
    }
}

function ShuffleEnv {
    $Keys = (
        "PATH", "LIB", "INCLUDE", "WindowsLibPath", "LIBPATH"
    )
    foreach ($k in $Keys) {
        $Value = [environment]::GetEnvironmentVariable($k)
        $vv = $Value.Split(";")
        [System.Text.StringBuilder]$newValue = New-Object -TypeName System.Text.StringBuilder
        $newValue.Capacity = $Value.Length
        foreach ($p in $vv) {
            if (![String]::IsNullOrEmpty($p)) {
                if ($newValue.Length -ne 0) {
                    [void]$newValue.Append(";")
                }
                [void]$newValue.Append($p)
            }
        }
        [environment]::SetEnvironmentVariable($k, $newValue.ToString())
    }
}