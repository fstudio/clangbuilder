#

# set windows 7 sdk environment
Function InitializeWindows7SDK {
    $SDKDir = "$env:HOMEDRIVE\Program Files (x86)\Microsoft SDKs\Windows\v7.1A"
    $env:PATH = "$env:PATH;$SDKDir\Bin"
    $env:LIB = "$env:LIB;$SDKDir\Lib\x64"# not support x86
    $env:INCLUDE = "$env:INCLUDE;$SDKDir\Include"
}

Function InitializeVisualCppTools {
    param(
        [string]$VSDir
    )
    
    $xml = [xml](Get-Content -Path "$VSDir\VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.props")
    $Version = $xml.Project.PropertyGroup.VCToolsVersion.'#text'
    $MSVCDir = "$VSDir\VC\Tools\MSVC\$Version"
    $env:PATH = "$env:PATH ;$MSVCDir\bin\Hostx64\x64"
    $env:LIB = "$env:LIB ;$MSVCDir\lib\x64;$MSVCDir\atlmfc\lib\x64"
    $env:INCLUDE = "$env:INCLUDE;$MSVCDir\include;$MSVCDir\atlmfc\include"
}

Function InitializeUCRT {
    param(
        [String]$Arch,
        [String]$HostEnv = "x64"
    )
    $sdk10 = "HKLM:SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0"
    if (!(Test-Path $sdk10)) {
        $sdk10 = "HKLM:SOFTWARE\Microsoft\Microsoft SDKs\Windows\v10.0"
    }
    $pt = Get-ItemProperty -Path $sdk10
    $version = "$($pt.ProductVersion).0"
    $installdir = $pt.InstallationFolder
    $env:INCLUDE = "$env:INCLUDE;${installdir}include\$version\ucrt"
    $env:LIB = "$env:LIB;${installdir}lib\$version\ucrt\x64"
}

Write-Host "Initialize Windows 7 SDK Environment`n"
$ClangbuilderRoot = Split-Path $PSScriptRoot
Import-Module "$ClangbuilderRoot\modules\PM"

$env:PATH = "$ClangbuilderRoot/pkgs/vswhere;$env:PATH"
$vsinstalls = $null
try {
    $vsinstalls = vswhere -prerelease -legacy -format json|ConvertFrom-JSON
}
catch {
    Write-Error "$_"
    Pop-Location
    exit 1
}

InitializePackageEnv -ClangbuilderRoot "$ClangbuilderRoot"
InitializeVisualCppTools -VSDir $vsinstalls[0].installationPath
InitializeWindows7SDK
InitializeUCRT