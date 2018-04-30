@Echo off
Title %CD% - Compile Clangbuilder UI
if exist "%~dp0..\bin\required_pwsh" (
    where pwsh >nul 2>nul || goto FALLBACK
    pwsh -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0../bin/Devinstall.ps1" upgrade --default
    goto :EOF
)

:FALLBACK
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0../bin/Devinstall.ps1" upgrade --default
