@Echo off
Title %CD% - Compile Clangbuilder UI
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0cmakeflags.ps1" %*
