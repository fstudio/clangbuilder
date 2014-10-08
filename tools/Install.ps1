
$toolsroot=Split-Path -Parent $MyInvocation.MyCommand.Definition
$CSvNRoot=Split-Path -Parent $toolsroot

Set-Location $toolsroot

IEX -Command "cmd /c ${toolsroot}\BuildNetTools.bat"

$ClangSetupvNextSetDir="${toolsroot}\ClangSetupvNextSet\ClangSetupvNextSet\bin\Release"
IF(!(Test-Path "${CSvNRoot}\Packages\NetTools"))
{
Mkdir "${CSvNRoot}\Packages\NetTools"
}

Copy-Item -Path "${ClangSetupvNextSetDir}\*" -Destination "${CSvNRoot}\Packages\NetTools" -Exclude *.vshost.*,*.pdb  -Force -Recurse

#IEX -Command "msbuild $toolsroot\ClangSetupvNextSet\ClangSetupvNextSet.sln /t:Clean"
#IEX -Command "msbuild $toolsroot\tools\ClangSetupvNextSet\ClangSetupvNextSet.sln /t:Clean"
IEX -Command "cmd /c ${toolsroot}\CleanNetTools.bat"

IF(!(Test-Path "${CSvNRoot}\Packages\NativeTools"))
{
Mkdir "${CSvNRoot}\Packages\NativeTools"
}
$osbit="OS32BIT"

IF([System.Environment]::Is64BitOperatingSystem -eq $True)
{
$osbit="OS64BIT"
}

IEX -Command "cmd /c ${toolsroot}\BuildNative.bat ${osbit}"
Copy-Item -Path "${CSvNRoot}\tools\Launcher\Launcher.exe"  -Destination "${CSvNRoot}\Packages\NativeTools"   -Force -Recurse
IEX -Command "cmd /c ${toolsroot}\Launcher\cleanBuild.bat"

Set-Location $CSvNRoot

