@echo off
echo Write PowerShell ExecutionPolicy
echo Windows Registry Editor Version 5.00 >%TEMP%\PowerShell.Setting.Reg
echo. >>%TEMP%\PowerShell.Setting.Reg
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell] >>%TEMP%\PowerShell.Setting.Reg
echo "ExecutionPolicy"="Unrestricted">>%TEMP%\PowerShell.Setting.Reg
echo. >>%TEMP%\PowerShell.Setting.Reg
echo [HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell] >>%TEMP%\PowerShell.Setting.Reg
echo "ExecutionPolicy"="Unrestricted" >>%TEMP%\PowerShell.Setting.Reg
echo. >>%TEMP%\PowerShell.Setting.Reg

regedit "%TEMP%\PowerShell.Setting.Reg"

del %TEMP%\PowerShell.Setting.Reg
pause
