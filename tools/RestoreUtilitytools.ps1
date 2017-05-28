<#############################################################################
#  RestoreUtilitytools.ps1
#  Note: Clang Auto Build Environment
#  Date:2016.01.02
#  Author:Force <forcemz@outlook.com>
##############################################################################>
$ClangBuilderRoot=Split-Path -Parent $PSScriptRoot
$NugetURL="https://dist.nuget.org/win-x86-commandline/v4.1.0/nuget.exe"

Function Get-RegistryValueEx{
    param(
        [ValidateNotNullorEmpty()]
        [String]$Path,
        [ValidateNotNullorEmpty()]
        [String]$Key
    )
    if(!(Test-Path $Path)){
        return 
    }
    (Get-ItemProperty $Path $Key).$Key
}

Function Invoke-BatchFile{
    param(
        [Parameter(Mandatory=$true)]
        [string] $Path,
        [string] $ArgumentList
    )
    Set-StrictMode -Version Latest
    $tempFile=[IO.Path]::GetTempFileName()
    cmd /c " `"$Path`" $argumentList && set > `"$tempFile`" "
    ## Go through the environment variables in the temp file.
    ## For each of them, set the variable in our local environment.
    Get-Content $tempFile | Foreach-Object {
        if($_ -match "^(.*?)=(.*)$")
        {
            Set-Content "env:\$($matches[1])" $matches[2]
        }
    }
    Remove-Item $tempFile
}


Push-Location $PWD
Set-Location $PSScriptRoot

if(!(Test-Path "$PSScriptRoot\NuGet\Nuget.exe")){
    Write-Output "Download NuGet now ....."
    Invoke-WebRequest $NugetURL -OutFile "$PSScriptRoot\NuGet\nuget.exe"
}

$RegRouter="HKLM:\SOFTWARE\Microsoft"
$IsWindows64=[System.Environment]::Is64BitOperatingSystem

IF($IsWindows64) {
    $RegRouter="HKLM:\SOFTWARE\Wow6432Node\Microsoft"
}

$VS15InstallRoot=Get-RegistryValueEx -Path "$RegRouter\VisualStudio\SxS\VS7" -Key "15.0"


$VisualStudioEnvBatch150="${VS15InstallRoot}\VC\Auxiliary\Build\vcvarsall.bat"
$VisualStudioEnvBatch140="$env:VS140COMNTOOLS..\..\VC\vcvarsall.bat"
$VisualStudioEnvBatch120="$env:VS120COMNTOOLS..\..\VC\vcvarsall.bat"
$VisualStudioEnvBatch110="$env:VS110COMNTOOLS..\..\VC\vcvarsall.bat"

$ArchArgument="x86"
$Arch="Win32"

if([System.Environment]::Is64BitOperatingSystem -eq $True)
{
    $ArchArgument="x86_amd64"
    $Arch="Win64"
}

if(Test-Path $VisualStudioEnvBatch150)
{
    Write-Host "Use Visual Studio 2017 $Arch"
    Invoke-BatchFile -Path $VisualStudioEnvBatch150 -ArgumentList $ArchArgument
}elseif(Test-Path $VisualStudioEnvBatch140){
    Write-Host "Use Visual Studio 2015 $Arch"
    Invoke-BatchFile -Path $VisualStudioEnvBatch140 -ArgumentList $ArchArgument
}elseif(Test-Path $VisualStudioEnvBatch120){
    Write-Host "Use Visual Studio 2013 $Arch"
    Invoke-BatchFile -Path $VisualStudioEnvBatch120 -ArgumentList $ArchArgument
}elseif(Test-Path $VisualStudioEnvBatch110){
    Write-Host "Use Visual Studio 2012 $Arch"
    Invoke-BatchFile -Path $VisualStudioEnvBatch110 -ArgumentList $ArchArgument
}else{
    Write-Error "ClangbuilderUI required Visual Studio 2013 or 2015 or 2017"
    return 1;
}

Set-Location "$PSScriptRoot\ClangbuilderUI"
Write-Host "Building ClangbuilderUI ..."
&nmake

if(!(Test-Path "ClangbuilderUI.exe")){
    Write-Error "Build ClangbuilderUI.exe failed"
    return 1
}

if(!(Test-Path "$PSScriptRoot\Restore"))
{
    mkdir -Force "$PSScriptRoot\Restore"
}

Copy-Item -Path "ClangbuilderUI.exe" -Destination "$ClangBuilderRoot\utils"
&nmake clean
Set-Location $PSScriptRoot


if(Test-Path "$ClangBuilderRoot\utils\ClangbuilderUI.exe"){
    if(!(Test-Path "$ClangBuilderRoot\ClangbuilderUI.lnk")){
        $cswshell=New-Object -ComObject WScript.Shell
        $clangbuilderlnk=$cswshell.CreateShortcut("$ClangBuilderRoot\ClangbuilderUI.lnk")
        $clangbuilderlnk.TargetPath="$ClangBuilderRoot\utils\ClangbuilderUI.exe"
        $clangbuilderlnk.Description="Start ClangbuilderUI"
        $clangbuilderlnk.WindowStyle=1
        $clangbuilderlnk.WorkingDirectory="$ClangBuilderRoot\utils"
        $clangbuilderlnk.IconLocation="$ClangBuilderRoot\utils\ClangbuilderUI.exe,0"
        $clangbuilderlnk.Save()
    }else{
        Write-Output "ClangbuilderUI.lnk already exists"
    }
}else{
    Write-Error "Cannot found ClangbuilderUI.exe "
}


Pop-Location
