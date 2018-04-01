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
    $env:PATH = "$ClangbuilderRoot" + [System.IO.Path]::DirectorySeparatorChar + "bin"+ [System.IO.Path]::PathSeparator+ $env:PATH 
    $InitializeFile = "$ClangbuilderRoot/config/initialize.json"
    if (!(Test-Path $InitializeFile)) {
        return 
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
}

Function InitializeExtranl {
    param(
        [ValidateSet("x86", "x64", "ARM", "ARM64")]
        [String]$Arch = "x64",
        [String]$ClangbuilderRoot
    )
    
    $ClangbuilderRoot = Split-Path -Parent $PSScriptRoot
    $ExtranllibsDir = "$ClangbuilderRoot\libs"
    
    if (Test-Path "$ExtranllibsDir\$Arch\include") {
        $env:INCLUDE = $env:INCLUDE + [System.IO.Path]::PathSeparator + "$ExtranllibsDir\$Arch\include"
    }
    if (Test-Path "$ExtranllibsDir\$Arch\lib") {
        $env:LIB = $env:LIB + [System.IO.Path]::PathSeparator + "$ExtranllibsDir\$Arch\lib"
    }
    if (Test-Path "$ExtranllibsDir\$Arch\bin") {
        $env:PATH = $env:PATH + [System.IO.Path]::PathSeparator + "$ExtranllibsDir\$Arch\bin"
    }
    
    if (Test-Path "$Extranllibs\$Arch\libs") {
        $env:LIB = $env:LIB + [System.IO.Path]::PathSeparator + "$ExtranllibsDir\$Arch\libs"
    }
    
}