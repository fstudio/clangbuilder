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
if(!(Test-Path "$SelfFolder\Restore"))
{
    mkdir -Force "$SelfFolder\Restore"
}
Copy-Item -Path "$ClangbuilderUIRelease\*" -Destination "$SelfFolder\Restore" -Exclude *.vshost.*,*.pdb  -Force -Recurse
&cmd /c "$SelfFolder\CleanTask.bat"

$Arch="32BIT"

if([System.Environment]::Is64BitOperatingSystem -eq $True)
{
    $Arch="64BIT"
}

if(Test-Path "$SelfFolder\Restore\ClangbuilderUI.exe"){
    if(!(Test-Path "$ClangBuilderRoot\ClangbuilderUI.lnk")){
        $cswshell=New-Object -ComObject WScript.Shell
        $clangbuilderlnk=$cswshell.CreateShortcut("$ClangBuilderRoot\ClangbuilderUI.lnk")
        $clangbuilderlnk.TargetPath="$SelfFolder\Restore\ClangbuilderUI.exe"
        $clangbuilderlnk.Description="Start ClangbuilderUI"
        $clangbuilderlnk.WindowStyle=1
        $clangbuilderlnk.WorkingDirectory="$ClangBuilderRoot\bin"
        $clangbuilderlnk.IconLocation="$SelfFolder\Restore\ClangbuilderUI.exe,0"
        $clangbuilderlnk.Save()
    }else{
        Write-Output "ClangbuilderUI.lnk already exists"
    }
}else{
    Write-Error "Cannot found ClangbuilderUI.exe "
}




&cmd /c "$SelfFolder\LauncherTask.bat" $Arch
Copy-Item -Path "$SelfFolder\Launcher\Launcher.exe"  -Destination "$SelfFolder\Restore"   -Force -Recurse
&cmd /c "$SelfFolder\Launcher\cleanBuild.bat"

Pop-Location
