@Echo off
Title Windows 7 SDK Environment ^for VS2017 [Win64]
PowerShell -NoProfile -NoExit -NoLogo -ExecutionPolicy unrestricted -File "%~dp0Windows7SDK.ps1"  -Arch x64 -UseVS2017 %* 
