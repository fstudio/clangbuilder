@echo off
::CleanBuil Task
if not exist "%VS140COMNTOOLS%"  goto VS120
call "%VS140COMNTOOLS%\VsDevCmd.bat"
goto ClangbuilderUITask
:VS120

IF not exist "%VS120COMNTOOLS%"  goto VS110
call "%VS120COMNTOOLS%\VsDevCmd.bat"
goto ClangbuilderUITask

:VS110
if not exist "%VS110COMNTOOLS%"  goto VAILDVSNOTFOUD
call "%VS110COMNTOOLS%\VsDevCmd.bat"
goto ClangbuilderUITask

:ClangbuilderUITask
cd /d %~dp0ClangbuilderUI
msbuild ClangbuilderUI.sln /t:Clean /p:Configuration=Release


goto :EOF
:VAILDVSNOTFOUD
echo Couldn't find valid VisualStudio
PAUSE