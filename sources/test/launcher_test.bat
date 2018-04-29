@Echo off
Title %CD% - Compile Clangbuilder UI
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0launcher_test.ps1" %*