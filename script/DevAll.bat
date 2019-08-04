@Echo off
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0../bin/devi.ps1" upgrade --default
