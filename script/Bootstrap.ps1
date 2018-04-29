#!/usr/bin/env pwsh
# TOO BOOTSTRAP ENVIRONMENT

# Check vswhere is exists.
$Cbroot=Split-Path $PSScriptRoot
$vswherebin="$Cbroot\bin\pkgs\vshwere\vswhere.exe"

Function Fetchvswhere{
    try{

    }catch{
        Write-Host "$_"
    }
}


if(!(Test-Path $vswherebin)){
    Write-Host "try download vswhere $vswherebin"
}