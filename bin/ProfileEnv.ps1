#

## TO enable TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot
$Pkglocksdir = "$ClangbuilderRoot/bin/pkgs/.locks"
if(Test-Path "$ClangbuilderRoot/config/profile.ps1"){
    ."$ClangbuilderRoot/config/profile.ps1"
}

Write-Debug $Pkglocksdir