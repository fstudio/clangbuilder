@Echo off

if exist "%~dp0required_pwsh" (
    where pwsh >nul 2>nul || goto FALLBACK
    pwsh -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0../bin/Devi.ps1" %*
    goto :EOF
)

:FALLBACK
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0../bin/Devi.ps1" %*
