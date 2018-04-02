@Echo off
Title %CD% - Devinstall upgrade packages.
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0../bin/Devinstall.ps1" upgrade --default