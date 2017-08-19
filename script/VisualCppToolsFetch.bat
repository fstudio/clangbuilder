@Echo off
Title %CD% - Fetch VisualCppTools
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -Command "[System.Threading.Thread]::CurrentThread.CurrentCulture = ''; [System.Threading.Thread]::CurrentThread.CurrentUICulture = '';& '%~dp0../bin/DownloadDailyCompiler.ps1' %*"
