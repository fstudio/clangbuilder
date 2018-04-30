@Echo off
Title Windows 7 SDK Environment ^for VS2015 [Win64]
if exist "%~dp0..\bin\required_pwsh" (
    where pwsh >nul 2>nul || goto FALLBACK
    pwsh -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0Windows7SDK.ps1" -Arch x64 %* 
    goto :EOF
)

:FALLBACK
PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0Windows7SDK.ps1" -Arch x64 %* 