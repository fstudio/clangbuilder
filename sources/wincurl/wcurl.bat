@Echo off

pwsh -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0wincurl.ps1" %*
