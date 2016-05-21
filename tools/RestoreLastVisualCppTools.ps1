<##########################################################################################
# Install VisualCppTools Prerelease
# Author: Force Charlie
# Date: 2016.02
# Copyright (C) 2016 Force Charlie. All Rights Reserved.
###########################################################################################>


# See https://blogs.msdn.microsoft.com/vcblog/2016/02/16/try-out-the-latest-c-compiler-toolset-without-waiting-for-the-next-update-of-visual-studio/
# nuget install VisualCppTools -source http://vcppdogfooding.azurewebsites.net/nuget/ -Prerelease

Push-Location $PWD
#XML sources: http://vcppdogfooding.azurewebsites.net/nuget/Packages
#$NuGetUserConfig="$env:AppData\NuGet\NuGet.config"
$NuGetAddSource="http://vcppdogfooding.azurewebsites.net/nuget/"
$VisualCppToolsInstallDir="$PSScriptRoot\msvc"
$NugetToolsDir="$PSScriptRoot\Nuget"
$VisualCppToolsPreRevision="14.0.24120-Pre"
$VisualCppToolsNameRevision="VisualCppTools.${VisualCppToolsPreRevision}"
$VisualCppToolsRevDir="$VisualCppToolsInstallDir\$VisualCppToolsNameRevision"
$NuGetURL="https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"

Function Get-NuGetFile{
    if(!(Test-Path "$PSScriptRoot\NuGet\nuget.exe")){
        Write-Output "Download NuGet now ....."
        Invoke-WebRequest $NuGetURL -OutFile "$PSScriptRoot\NuGet\nuget.exe"
    }
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

if(!(Test-ExecuteFile "nuget")){
    $env:PATH=$env:PATH+";"+$NugetToolsDir
}

if(!(Test-Path $VisualCppToolsInstallDir)){
    mkdir -Force $VisualCppToolsInstallDir
}

Set-Location $VisualCppToolsInstallDir

if(!(Test-Path $VisualCppToolsRevDir)){
    Write-Output "NuGet Install VisualCppTools ......"
    #&nuget  install VisualCppTools -Source $NuGetAddSource -Version $VisualCppToolsPreRevision -Prerelease
	&nuget  install VisualCppTools -Source $NuGetAddSource  -Prerelease
}

Pop-Location 
