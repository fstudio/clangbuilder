@Echo off
Title %CD% - Restore Last Visual C^+^+ Tools
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -Command "[System.Threading.Thread]::CurrentThread.CurrentCulture = ''; [System.Threading.Thread]::CurrentThread.CurrentUICulture = '';& '%~dp0RestoreLastVisualCppTools.ps1' %*"