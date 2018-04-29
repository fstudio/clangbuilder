@echo off
title "Initialize Clangbuilder"
if not exist "%~dp0../bin/blast.exe" (
	PowerShell -NoProfile -NoLogo -ExecutionPolicy unrestricted -File "%~dp0Bootstrap.ps1"
)
call "%~dp0DevAll.bat"
call "%~dp0CompileUI.bat"
