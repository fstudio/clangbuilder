@echo off
if not exist "%~dp0pkgs\.temp" (
	mkdir "%~dp0pkgs\.temp"
)
cd %~dp0pkgs\.temp
wget --content-disposition %*