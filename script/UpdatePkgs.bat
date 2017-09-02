@Echo off
Title %CD% - Update Packages
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0../bin/InstallUtils.ps1" %*