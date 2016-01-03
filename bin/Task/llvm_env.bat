@ECHO OFF

IF "%1" == "build" goto do_build
IF "%1" == "dev" goto do_dev
ECHO Unknown option, expected "build" or "dev"
goto do_end

:do_build
ECHO Initializing MSVC Build Environment...
CALL "C:\Program Files (x86)\Microsoft Visual Studio 12.0\vc\vcvarsall.bat"
ECHO Initializing Python environment...
set PYTHONPATH=<python src dir>\Lib;<cmake gen dir>\lib\site-packages
set PATH=%PATH%;<python src dir>\PCbuild
goto do_end

:do_dev
set PYTHONPATH=
goto do_end
:do_end
