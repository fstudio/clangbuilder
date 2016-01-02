<#############################################################################
#  RestoreUtilitytools.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>    
##############################################################################>
$SelfFolder=Split-Path -Parent $MyInvocation.MyCommand.Definition
$ClangBuilderRoot=Split-Path -Parent $SelfFolder

Set-Location $SelfFolder
IEX -Command "cmd /c $SelfFolder\ClangbuilderUITask.bat"
$ClangbuilderUIRelease="$SelfFolder\ClangbuilderUI\ClangbuilderUI\bin\Release"
IF(!(Test-Path "$SelfFolder\Restore"))
{
    mkdir "$SelfFolder\Restore"
}
Copy-Item -Path "$ClangbuilderUIRelease\*" -Destination "$SelfFolder\Restore" -Exclude *.vshost.*,*.pdb  -Force -Recurse
IEX -Command "cmd /c ${SelfFolder}\CleanTask.bat"

$osbit="32BIT"

IF([System.Environment]::Is64BitOperatingSystem -eq $True)
{
$osbit="64BIT"
}

IF(!(Test-Path "$ClangBuilderRoot\ClangbuilderUI.lnk")){
    $cswshell=New-Object -ComObject WScript.Shell
    $wpfshortcut=$cswshell.CreateShortcut("$ClangBuilderRoot\ClangbuilderUI.lnk")
    $wpfshortcut.TargetPath="$SelfFolder\Restore\ClangbuilderUI.exe"
    $wpfshortcut.Description="Start ClangbuilderUI"
    $wpfshortcut.WindowStyle=1
    $wpfshortcut.WorkingDirectory="$ClangBuilderRoot\bin"
    $wpfshortcut.IconLocation="$SelfFolder\Restore\ClangbuilderUI.exe,0"
    $wpfshortcut.Save()
}


IEX -Command "cmd /c $SelfFolder\LauncherTask.bat ${osbit}"
Copy-Item -Path "$SelfFolder\Launcher\Launcher.exe"  -Destination "$SelfFolder\Restore"   -Force -Recurse
IEX -Command "cmd /c $SelfFolder\Launcher\cleanBuild.bat"


