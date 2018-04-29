#!/usr/bin/env pwsh
# TOO BOOTSTRAP ENVIRONMENT

# Check vswhere is exists.
$Cbroot = Split-Path $PSScriptRoot
$vswherebin = "$Cbroot\bin\pkgs\vswhere\vswhere.exe"

Function Fetchvswhere {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $json=Get-Content "$Cbroot\ports\vswhere.json"|ConvertFrom-Json
        $InternalUA = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
        New-Item -ItemType Directory "$env:TEMP\vswhere.$PID"|Out-Null
        Invoke-WebRequest -Uri $json.url -OutFile "$TEMP\vswhere.$PID\vswhere.exe" -UserAgent $InternalUA -UseBasicParsing
        $env:PATH="$env:PATH;$env:TEMP\vswhere.$PID"
    }
    catch {
        Write-Host "download vswhere error$_"
        exit 1
    }
}


if (Test-Path $vswherebin) {
    $env:PATH="$env:PATH;$Cbroot\bin\pkgs\vshwere"
}else{
    Write-Host "try download vswhere $vswherebin"
    Fetchvswhere
}

Invoke-Expression "$Cbroot\bin\CompileUtils.ps1"
