@Echo off
Title %CD% - Update Packages
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0../bin/Devinstall.ps1" upgrade