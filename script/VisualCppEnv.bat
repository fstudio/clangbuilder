@Echo off
Title %CD% - Fetch VisualCppTools
PowerShell -NoExit -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0../bin/VisualCppToolsEnv.ps1" %*
