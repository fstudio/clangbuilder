@Echo off
Title Windows 7 SDK Environment ^for VS2015 [Win32]
if exist "%~dp0..\bin\required_pwsh" (
    where pwsh >nul 2>nul || goto FALLBACK
    pwsh -NoProfile -NoExit -NoLogo -ExecutionPolicy unrestricted -File "%~dp0Windows7SDK.ps1" -Arch x86 %* 
    goto :EOF
)

:FALLBACK
PowerShell -NoProfile -NoExit -NoLogo -ExecutionPolicy unrestricted -File "%~dp0Windows7SDK.ps1" -Arch x86 %* 
