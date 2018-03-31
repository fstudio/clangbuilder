#

## TO enable TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot
$Devlockfile="$ClangbuilderRoot/bin/pkgs/devlocks.json"