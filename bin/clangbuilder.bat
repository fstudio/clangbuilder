@Echo off
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0ClangbuilderTarget.ps1" %*
