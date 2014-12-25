@echo off
::Update
if not exist "%~dp0InstallClangSetupvNext.ps1" goto NotFound
start PowerShell -NoLogo -NoExit   -File "%~dp0InstallClangSetupvNext.ps1"
goto :EOF

:NotFound
echo Not Found InstallClangSetupvNext,Your Should Reset ClangSetupvNext
echo "Your Can: git clone https://github.com/forcegroup/ClangSetupvNext.git"
PAUSE

