@Echo off
Title %CD% - Fetch VisualCppTools
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0../bin/VisualCppDaily.ps1" %*
