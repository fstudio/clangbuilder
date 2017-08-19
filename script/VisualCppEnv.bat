@Echo off
Title %CD% - Fetch VisualCppTools
PowerShell -NoExit -NoProfile -NoLogo -ExecutionPolicy unrestricted -Command "[System.Threading.Thread]::CurrentThread.CurrentCulture = ''; [System.Threading.Thread]::CurrentThread.CurrentUICulture = '';& '%~dp0../bin/VisualCppToolsEnv.ps1' %*"
