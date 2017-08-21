@Echo off
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -Command "[System.Threading.Thread]::CurrentThread.CurrentCulture = '';& '%~dp0ClangbuilderTarget.ps1' %*"
