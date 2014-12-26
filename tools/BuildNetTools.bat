@echo off
IF not exist "%VS120COMNTOOLS%"  goto VS110ENVCALL
call "%VS120COMNTOOLS%\VsDevCmd.bat"
goto BuildCSVNS
:VS110ENVCALL
if not exist "%VS110COMNTOOLS%"  goto VS140ENVCALL
call "%VS110COMNTOOLS%\VsDevCmd.bat"
goto BuildCSVNS
:VS140ENVCALL
if not exist "%VS140COMNTOOLS%"  goto VAILDVSNOTFOUD
call "%VS140COMNTOOLS%\VsDevCmd.bat"
goto BuildCSVNS
:BuildCSVNS
SET PATH=%~dp0NuGet;%PATH%
cd /d %~dp0ClangSetupvNextSet
nuget restore
msbuild ClangSetupvNextSet.sln /t:Build /p:Configuration=Release


goto :EOF
:VAILDVSNOTFOUD
echo Couldn't find valid VisualStudio
PAUSE

