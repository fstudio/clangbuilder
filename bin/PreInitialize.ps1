## TO enable TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Function ReinitializePath {
    if ($PSEdition -eq "Desktop" -or $IsWindows) {
        [System.Text.StringBuilder]$PathSb = "";
        [void]$PathSb.Append($env:windir)
        [void]$PathSb.Append(";${env:windir}\System32")
        [void]$PathSb.Append(";${env:windir}\System32\Wbem")
        [void]$PathSb.Append(";${env:windir}\System32\WindowsPowerShell\v1.0")
        $env:PATH = $PathSb.ToString()
    }
    else {
        $env:PATH = "/usr/local/bin:/usr/bin:/bin"
    }
}

$ClangbuilderRoot = Split-Path -Parent $PSScriptRoot
$Pkglocksdir = "$ClangbuilderRoot/bin/pkgs/.locks"