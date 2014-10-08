@echo off
::Build Native Tools Such as Launcher.
::PowerShell Must input param 
::BuildNative.bat OS64BIT or OS32BIT or OSARM OSAArch64
::Read http://msdn.microsoft.com/en-us/library/hs24szh9.aspx |http://msdn.microsoft.com/en-us/library/hs24szh9(v=vs.120).aspx
::VisualStudio Express for Windows Desktop Support 32-bit X86 compiler X86_ x64 cross-compiler
::VisualStudio Express for Windows Support 32-bit X86 compiler X86_ x64 cross-compiler X86_arm cross-compiler
::This Tools Must use Visual Studio 11(2012) or Later
IF /i "%1" =="OS64BIT" goto OS64BIT
IF /i "%1" == "OS32BIT" goto OS32BIT
IF /i "%1" == "OSARM" goto OSARM
IF /i "%1" == "OSAArch64" goto OSAARCH64
echo "Goto Default System 32BIT....."
goto OS32BIT
:OS64BIT
goto VS120ENVCALL64C
:OS32BIT
if exist "%SystemRoot%\SysWOW64" goto OS64BIT
goto VS120ENV86CALL
:OSARM
if not exist "%VS140COMNTOOLS%..\..\VC\bin\x86_arm" goto VAILDVSNOTFOUD
call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat"  x86_arm
goto BuildNative

:OSAARCH64
echo "Not Open Support Now"
goto :EOF


::64BIT Build
:VS120ENVCALL64C
IF not exist "%VS120COMNTOOLS%..\..\VC\bin\x86_amd64"  goto VS110ENVCALL64C
call "%VS120COMNTOOLS%..\..\VC\vcvarsall.bat"  x86_amd64
goto BuildNative

:VS110ENVCALL64C
if not exist "%VS110COMNTOOLS%..\..\VC\bin\x86_amd64"  goto VS140ENVCALL64C
call "%VS110COMNTOOLS%..\..\VC\vcvarsall.bat"  x86_amd64
goto BuildNative

:VS110ENVCALL64C
if not exist "%VS140COMNTOOLS%..\..\VC\bin\x86_amd64"  goto VAILDVSNOTFOUD
call "%VS140COMNTOOLS%..\..\VC\vcvarsall.bat"  x86_amd64
goto BuildNative

::X86 Build
:VS120ENV86CALL
IF not exist "%VS120COMNTOOLS%"  goto VS10ENVC86ALL
call "%VS120COMNTOOLS%.\VsDevCmd.bat" 
goto BuildNative

:VS110ENVC86ALL
if not exist %VS110COMNTOOLS%  goto VS140ENVC86ALL
call "%VS110COMNTOOLS%\VsDevCmd.bat"
goto BuildNative

:VS140ENV86CALL
if not exist %VS140COMNTOOLS%  goto VAILDVSNOTFOUD
call "%VS140COMNTOOLS%\VsDevCmd.bat"
goto BuildNative



:BuildNative
cd /d %~dp0Launcher
nmake -f Makefile.mk


goto :EOF
:VAILDVSNOTFOUD
echo Couldn't find valid VisualStudio

