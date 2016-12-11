<##########################################################################################
# Build git use Visual Studio 2015
# Author: Force Charlie
# Date: 2016.12
# Copyright (C) 2016 Force Charlie. All Rights Reserved.
###########################################################################################>

Push-Location $PWD
$GitSourcesDir="$PSScriptRoot\Git"
$NugetToolsDir="$PSScriptRoot\Nuget"
$NuGetURL="https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"

Function Get-NuGetFile{
    if(!(Test-Path "$PSScriptRoot\NuGet\nuget.exe")){
        Write-Output "Download NuGet now ....."
        Invoke-WebRequest $NuGetURL -OutFile "$PSScriptRoot\NuGet\nuget.exe"
    }
}

Function Test-AddPath{
    param(
        [String]$Path
    )
    if(Test-Path $Path){
        $env:Path="$Path;${env:Path}"
    }
}

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

Function Test-ExecuteFile
{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter Execute Name")]
        [ValidateNotNullorEmpty()]
        [String]$ExeName
    )
    $myErr=@()
     Get-command -CommandType Application $ExeName -ErrorAction SilentlyContinue -ErrorVariable +myErr
     if($myErr.count -eq 0)
     {
         return $True
     }
     return $False
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



if(!(Test-ExecuteFile "nuget")){
    $env:PATH=$env:PATH+";"+$NugetToolsDir
}

if(!(Test-ExecuteFile "git")){
    $gitkey="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
    $gitkey2="HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
    if(Test-Path $gitkey){
       $gitinstall=Get-RegistryValueEx $gitkey "InstallLocation"
       Test-AddPath "${gitinstall}\bin"
    }elseif(Test-Path $gitkey2){
        $gitinstall=Get-RegistryValueEx $gitkey2 "InstallLocation"
        Test-AddPath "${gitinstall}\bin"
    }
}


if(!(Test-Path $GitSourcesDir)){
    &git clone -b "vs/master" "https://github.com/git-for-windows/git.git" Git
}

if(!(Test-Path "$GitSourcesDir/git.sln")){
    Write-Error "Not Found git.sln from $GitSourcesDir, Please check error"
    exit 1
}


$VisualStudioEnvBatch140="$env:VS140COMNTOOLS..\..\VC\vcvarsall.bat"

$ArchArgument="x86"
$Arch="Win32"

if([System.Environment]::Is64BitOperatingSystem -eq $True)
{
    $ArchArgument="x86_amd64"
    $Arch="x64"

}

if(Test-Path $VisualStudioEnvBatch140){
    Write-Host "Use Visual Studio 2015 $Arch"
    Invoke-BatchFile -Path $VisualStudioEnvBatch140 -ArgumentList $ArchArgument
}else{
    Write-Error "Only support Visual Studio 2015"
    exit 1
}

Set-Location $GitSourcesDir

&nuget restore
&msbuild git.sln /t:Rebuild /p:Configuration="Release" /p:Platform="$Arch"