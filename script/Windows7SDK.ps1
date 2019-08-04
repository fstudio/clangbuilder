#
param(
    [Switch]$UseVS2017,
    [ValidateSet("x86", "x64")]
    [String]$Arch = "x64"
)


# set windows 7 sdk environment
Function InitializeWindows7SDK {
    param(
        [String]$Arch
    )
    $SDKDir = "$env:HOMEDRIVE\Program Files (x86)\Microsoft SDKs\Windows\v7.1A"
    if ($Arch -eq "x64") {
        $env:PATH = "$env:PATH;$SDKDir\Bin\x64"
        $env:LIB = "$env:LIB;$SDKDir\Lib\x64"# not support x86
    }
    else {
        $env:PATH = "$env:PATH;$SDKDir\Bin"
        $env:LIB = "$env:LIB;$SDKDir\Lib"# not support x86
    }

    $env:INCLUDE = "$env:INCLUDE;$SDKDir\Include"
}

Function InitializeVisualStudio2017Compiler {
    param(
        [string]$VSDir,
        [String]$Arch
    )
    $xml = [xml](Get-Content -Path "$VSDir\VC\Auxiliary\Build\Microsoft.VCToolsVersion.default.props")
    $Version = $xml.Project.PropertyGroup.VCToolsVersion.'#text'
    $MSVCDir = "$VSDir\VC\Tools\MSVC\$Version"
    $env:PATH = "$env:PATH;$MSVCDir\bin\Host$Arch\$Arch"
    $env:LIB = "$env:LIB;$MSVCDir\lib\$Arch;$MSVCDir\atlmfc\lib\$Arch"
    $env:INCLUDE = "$env:INCLUDE;$MSVCDir\include;$MSVCDir\atlmfc\include"
}

Function InitializeVisualStudio2015Compiler {
    param(
        [string]$Arch
    )
    $VSDir = (Get-Item "$env:VS140COMNTOOLS\..\..").FullName
    if ($Arch -eq "x64") {
        $env:PATH = "$env:PATH;$VSDir\VC\bin\amd64"
        $env:LIB = "$env:LIB;$VSDir\VC\lib\amd64;$VSDir\atlmfc\lib\amd64"
    }
    else {
        $env:PATH = "$env:PATH;$VSDir\VC\bin;$VSDir\Common7\IDE"
        $env:LIB = "$env:LIB;$VSDir\VC\lib;$VSDir\atlmfc\lib"
    }

    $env:INCLUDE = "$env:INCLUDE;$VSDir\VC\include;$VSDir\VC\atlmfc\include"
}

Function InitializeUCRT {
    param(
        [String]$Arch
    )
    $sdk10 = "HKLM:SOFTWARE\WOW6432Node\Microsoft\Microsoft SDKs\Windows\v10.0"
    if (!(Test-Path $sdk10)) {
        $sdk10 = "HKLM:SOFTWARE\Microsoft\Microsoft SDKs\Windows\v10.0"
    }
    $pt = Get-ItemProperty -Path $sdk10
    $version = "$($pt.ProductVersion).0"
    $installdir = $pt.InstallationFolder
    $env:INCLUDE = "$env:INCLUDE;${installdir}include\$version\ucrt"
    $env:LIB = "$env:LIB;${installdir}lib\$version\ucrt\$Arch"
}

$Text = "Visual C++ 2015"


$ClangbuilderRoot = Split-Path $PSScriptRoot
Import-Module "$ClangbuilderRoot\modules\Devi"
$ret = DevinitializeEnv -ClangbuilderRoot $ClangbuilderRoot

if ($ret -ne $true) {
    #TODO
}

if ($UseVS2017) {
    $Text = "Visual C++ 2017"
    $env:PATH = "$ClangbuilderRoot/pkgs/vswhere;$env:PATH"
    $vsinstalls = $null
    try {
        $vsinstalls = vswhere -prerelease -legacy -format json | ConvertFrom-Json
    }
    catch {
        Write-Error "$_"
        Pop-Location
        exit 1
    }
    InitializeVisualStudio2017Compiler -VSDir $vsinstalls[0].installationPath  -Arch $Arch

}
else {
    InitializeVisualStudio2015Compiler -Arch $Arch
}
Write-Host "Initialize Windows 7 SDK Environment
Please use -D_USING_V110_SDK71_=1 /Zc:threadSafeInit-
Use $Text Arch: $Arch
`n"

InitializeWindows7SDK -Arch $Arch
InitializeUCRT -Arch $Arch