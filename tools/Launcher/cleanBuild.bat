@echo off
cd /d %~dp0
del /s /q *.obj *.exe *.res  *.pdb >nul 2>nul
goto :EOF