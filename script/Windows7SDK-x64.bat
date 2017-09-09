@Echo off
Title %CD% - Windows 7 SDK Environment (x64)
PowerShell -NoProfile -NoExit -NoLogo -ExecutionPolicy unrestricted -File "%~dp0Windows7SDK-x64.ps1" %*