@Echo off
Title %CD% - devinstall console
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0../bin/Devinstall.ps1" %*