@Echo off
Title Windows 7 SDK Environment ^for VS2015 [Win32]
PowerShell -NoProfile -NoExit -NoLogo -ExecutionPolicy unrestricted -File "%~dp0Windows7SDK.ps1" -Arch x86 %* 