@echo off
REM cannot use this batch file !
set curDir=%~dp0

@call :GetWindowsSdkDir
@call :GetWindowsSdkExecutablePath32
@call :GetWindowsSdkExecutablePath64
@call :GetExtensionSdkDir
@call :GetVCInstallDir
@call :GetUniversalCRTSdkDir
set VCInstallDir=%~dp0msvc\VisualCppTools.14.0.23811-Pre\lib\native\

if not "%UniversalCRTSdkDir%" == "" @set UCRTContentRoot=%UniversalCRTSdkDir%
if not exist "%~dp0..\MSBuild\Microsoft.Cpp\v4.0\v140\" goto error_no_VCTARGETS
cd "%~dp0..\MSBuild\Microsoft.Cpp\v4.0\v140\"
set VCTargetsPath=%cd%\
cd %curDir%