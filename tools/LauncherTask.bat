@echo off
::Launcher build task batch
::PowerShell Must input param
::Launcher 64BIT | 32BIT | ARM | ARM64
::Read http://msdn.microsoft.com/en-us/library/hs24szh9.aspx |http://msdn.microsoft.com/en-us/library/hs24szh9(v=vs.120).aspx
::VisualStudio Express for Windows Desktop Support 32-bit X86 compiler X86_ x64 cross-compiler
::VisualStudio Express for Windows Support 32-bit X86 compiler X86_ x64 cross-compiler X86_arm cross-compiler
::Require Visual Studio 2012 or Later, Default Visual Studio 2015
IF /i "%1" =="64BIT" goto AMD64
IF /i "%1" == "32BIT" goto Intel32
IF /i "%1" == "ARM" goto ARM
IF /i "%1" == "ARM64" goto ARM64
echo "LauncherBuildTask default target is x86....."
goto Intel32

:AMD64
goto VS140USE64BIT

:Intel32
if exist "%SystemRoot%\SysWOW64" goto AMD64
goto VS140USE32BIT

:ARM
if not exist "%VS140COMNTOOLS%..\..\VC\bin\x86_arm" goto VAILDVSNOTFOUD
call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat"  x86_arm
goto LauncherBuildTask

:ARM64
if not exist "%VS140COMNTOOLS%..\..\VC\bin\x86_arm64" goto VAILDVSNOTFOUD
call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat"  x86_arm64
goto LauncherBuildTask

goto :EOF



::64BIT Build

:VS140USE64BIT
if not exist "%VS140COMNTOOLS%..\..\VC\bin\x86_amd64" goto VS120USE64BIT
call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat"  x86_amd64
goto LauncherBuildTask

:VS120USE64BIT
IF not exist "%VS120COMNTOOLS%..\..\VC\bin\x86_amd64"  goto VS110USE64BIT
call "%VS120COMNTOOLS%..\..\VC\vcvarsall.bat"  x86_amd64
goto LauncherBuildTask

:VS110USE64BIT
if not exist "%VS110COMNTOOLS%..\..\VC\bin\x86_amd64"  goto VAILDVSNOTFOUD
call "%VS110COMNTOOLS%..\..\VC\vcvarsall.bat"  x86_amd64
goto LauncherBuildTask


::X86 Build
:VS140USE32BIT
if not exist %VS140COMNTOOLS%  goto VS120USE32BIT
call "%VS140COMNTOOLS%\VsDevCmd.bat"
goto LauncherBuildTask

:VS120USE32BIT
IF not exist "%VS120COMNTOOLS%"  goto VS110USE32BIT
call "%VS120COMNTOOLS%.\VsDevCmd.bat"
goto LauncherBuildTask

:VS110USE32BIT
if not exist %VS110COMNTOOLS%  goto VAILDVSNOTFOUD
call "%VS110COMNTOOLS%\VsDevCmd.bat"
goto LauncherBuildTask

:LauncherBuildTask
cd /d %~dp0Launcher
nmake -f Makefile.mk


goto :EOF
:VAILDVSNOTFOUD
echo Couldn't find valid VisualStudio
PAUSE
