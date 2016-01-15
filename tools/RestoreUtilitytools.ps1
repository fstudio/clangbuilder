<#############################################################################
#  RestoreUtilitytools.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>
##############################################################################>
$SelfFolder=$PSScriptRoot;
$ClangBuilderRoot=Split-Path -Parent $SelfFolder

Push-Location $PWD
Set-Location $SelfFolder
&cmd /c "$SelfFolder\ClangbuilderUITask.bat"
$ClangbuilderUIRelease="$SelfFolder\ClangbuilderUI\ClangbuilderUI\bin\Release"
IF(!(Test-Path "$SelfFolder\Restore"))
{
    mkdir -Force "$SelfFolder\Restore"
}
Copy-Item -Path "$ClangbuilderUIRelease\*" -Destination "$SelfFolder\Restore" -Exclude *.vshost.*,*.pdb  -Force -Recurse
&cmd /c "$SelfFolder\CleanTask.bat"

$Arch="32BIT"

IF([System.Environment]::Is64BitOperatingSystem -eq $True)
{
$Arch="64BIT"
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


&cmd /c "$SelfFolder\LauncherTask.bat" $Arch
Copy-Item -Path "$SelfFolder\Launcher\Launcher.exe"  -Destination "$SelfFolder\Restore"   -Force -Recurse
&cmd /c "$SelfFolder\Launcher\cleanBuild.bat"

Pop-Location
