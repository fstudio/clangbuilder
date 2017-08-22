@Echo off
PowerShell -NoProfile -NoLogo -NoExit -ExecutionPolicy unrestricted -File "%~dp0ClangbuilderTarget.ps1" %*
