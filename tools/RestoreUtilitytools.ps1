<#############################################################################
#  RestoreUtilitytools.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>
##############################################################################>
$ClangBuilderRoot=Split-Path -Parent $PSScriptRoot
$NugetURL="https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"

Push-Location $PWD
Set-Location $PSScriptRoot

if(!(Test-Path "$PSScriptRoot\NuGet\Nuget.exe")){
    Write-Output "Download NuGet now ....."
    Invoke-WebRequest $NugetURL -OutFile "$PSScriptRoot\NuGet\nuget.exe"
}

&cmd /c "$PSScriptRoot\ClangbuilderUITask.bat"
$ClangbuilderUIRelease="$PSScriptRoot\ClangbuilderUI\ClangbuilderUI\bin\Release"
if(!(Test-Path "$PSScriptRoot\Restore"))
{
    mkdir -Force "$PSScriptRoot\Restore"
}
Copy-Item -Path "$ClangbuilderUIRelease\*" -Destination "$PSScriptRoot\Restore" -Exclude *.vshost.*,*.pdb  -Force -Recurse
&cmd /c "$PSScriptRoot\CleanTask.bat"

$Arch="32BIT"

if([System.Environment]::Is64BitOperatingSystem -eq $True)
{
    $Arch="64BIT"
}

if(Test-Path "$PSScriptRoot\Restore\ClangbuilderUI.exe"){
    if(!(Test-Path "$ClangBuilderRoot\ClangbuilderUI.lnk")){
        $cswshell=New-Object -ComObject WScript.Shell
        $clangbuilderlnk=$cswshell.CreateShortcut("$ClangBuilderRoot\ClangbuilderUI.lnk")
        $clangbuilderlnk.TargetPath="$PSScriptRoot\Restore\ClangbuilderUI.exe"
        $clangbuilderlnk.Description="Start ClangbuilderUI"
        $clangbuilderlnk.WindowStyle=1
        $clangbuilderlnk.WorkingDirectory="$ClangBuilderRoot\bin"
        $clangbuilderlnk.IconLocation="$PSScriptRoot\Restore\ClangbuilderUI.exe,0"
        $clangbuilderlnk.Save()
    }else{
        Write-Output "ClangbuilderUI.lnk already exists"
    }
}else{
    Write-Error "Cannot found ClangbuilderUI.exe "
}




&cmd /c "$PSScriptRoot\LauncherTask.bat" $Arch
Copy-Item -Path "$PSScriptRoot\Launcher\Launcher.exe"  -Destination "$PSScriptRoot\Restore"   -Force -Recurse
&cmd /c "$PSScriptRoot\Launcher\cleanBuild.bat"

Pop-Location
