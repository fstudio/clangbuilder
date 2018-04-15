@Echo off
Title %CD% - devi console
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0../bin/Devinstall.ps1" %*