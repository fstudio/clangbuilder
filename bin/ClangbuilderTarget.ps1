#!/usr/bin/env powershell

param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch = "x64",

    [ValidateSet("Release", "Debug", "MinSizeRel", "RelWithDebug")]
    [String]$Flavor = "Release",

    [String]$InstallId, # install id
    [String]$InstallationVersion, # installationVersion
    [Switch]$Environment, # start environment 
    [Switch]$Sdklow, # low sdk support
    [Switch]$LLDB,
    [Switch]$Bootstrap,
    [Switch]$Static,
    [Switch]$Latest,
    [Switch]$Package,
    #[Switch]$Libcxx,
    [Switch]$ClearEnv
)


if ($ClearEnv) {
    $env:Path = "${env:windir};${env:windir}\System32;${env:windir}\System32\Wbem;${env:windir}\System32\WindowsPowerShell\v1.0"
}

## initialize
. "$PSScriptRoot/Initialize.ps1"

. "$PSScriptRoot/PathLoader.ps1"

$VisualStudioArgs = "$PSScriptRoot/VisualStudioEnvinitEx.ps1 -Arch $Arch -InstallId $InstallId"

if ($Sdklow) {
    $VisualStudioArgs += " -Sdklow"
}

Invoke-Expression -Command $VisualStudioArgs
Invoke-Expression -Command "$PSScriptRoot/Extranllibs.ps1 -Arch $Arch"


if ($Environment) {
    Update-Title -Title " [Environment]"
    Set-Location $ClangbuilderRoot
    return ;
}

$Global:LLDB = $LLDB
if ($Latest) {
    $Global:LLVMInitializeArgs = "$Global:ClangbuilderRoot\bin\LLVMInitialize.ps1"
}
else {
    $Global:LLVMInitializeArgs = "$Global:ClangbuilderRoot\bin\LLVMInitializeEx.ps1"
}

if ($Latest) {
    Write-Host "Build llvm latest released version"
    $Global:LLVMSource = "$Global:ClangbuilderRoot\out\release"
}
else {
    Write-Host "Build llvm trunk"
    $Global:LLVMSource = "$Global:ClangbuilderRoot\out\mainline"
    $Global:LLVMInitializeArgs += " -Mainline"
}

if ($Global:LLDB) {
    $Global:LLVMInitializeArgs += " -LLDB"
}

# Update LLVM sources
Invoke-Expression -Command $Global:LLVMInitializeArgs



$ArchTable = @{
    "x86"   = "";
    "x64"   = "Win64";
    "ARM"   = "ARM";
    "ARM64" = "ARM64"
}

$ArchName = $ArchTable[$Arch];

# Builder CMake Arguments
$Global:Installation = $InstallationVersion.Substring(0, 2)

if ($Bootstrap) {
    if (!(Test-Path "$ClangbuilderRoot/out/build_stage0")) {
        mkdir -Force "$ClangbuilderRoot/out/build_stage0"
    }
    else {
        Remove-Item -Force -Recurse "$ClangbuilderRoot/out/build_stage0/*"
    }
    Set-Location "$ClangbuilderRoot/out/build_stage0"
    $Global:CMakeArguments = "-GNinja -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON -DCMAKE_BUILD_TYPE=Release -DLLVM_USE_CRT_RELEASE=MT"
    $Global:CMakeArguments += "  -DCMAKE_INSTALL_UCRT_LIBRARIES=ON -DLLDB_RELOCATABLE_PYTHON=1"
}
else {
    if (!(Test-Path "$ClangbuilderRoot/out/msbuild")) {
        mkdir -Force "$ClangbuilderRoot/out/msbuild"
    }
    else {
        Remove-Item -Force -Recurse "$ClangbuilderRoot/out/msbuild/*"
    }
    Set-Location "$ClangbuilderRoot/out/msbuild"
    $Global:CMakeArguments = "-G`"Visual Studio $Global:Installation $ArchName`""
    if ([System.Environment]::Is64BitOperatingSystem) {
        $Global:CMakeArguments += " -Thost=x64";
    }
    $Global:CMakeArguments += " -DCMAKE_CONFIGURATION_TYPES=$Flavor -DCMAKE_BUILD_TYPE=$Flavor"
    $Global:CMakeArguments += " -DLLVM_APPEND_VC_REV=ON -DBUILD_SHARED_LIBS=ON"
    # -DLLVM_ENABLE_LIBCXX=ON -DLLVM_ENABLE_MODULES=ON -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON
    $UpFlavor = $Flavor.ToUpper()
    if ($Flavor -eq "Release" -or $Flavor -eq "MinSizeRel") {
        $MTStaticLINK = "MT"
    }
    else {
        $MTStaticLINK = "MTd"
    }
    if ($Static) {
        $Global:CMakeArguments += " -DLLVM_USE_CRT_$UpFlavor=$MTStaticLINK"
    }
}





if ($LLDB) {
    . "$PSScriptRoot\LLDBInitialize.ps1"
    $PythonHome = Get-Pyhome -Arch $Arch
    if ($null -eq $PythonHome) {
        Write-Error "Please Install Python 3.5+ ! "
        Exit 
    }
    Write-Host -ForegroundColor Yellow "Building LLVM with lldb,msbuild, $VisualStudioTarget"
    $Global:CMakeArguments += " -DPYTHON_HOME=`"$PythonHome`" -DLLDB_RELOCATABLE_PYTHON=1"
}

$Global:CMakeArguments += " `"$Global:LLVMSource`""
$Global:CMakeArgv = $Global:CMakeArguments.Split()
Write-Host "cmake $Global:CMakeArgv"

&cmake $Global:CMakeArgv
if ($lastexitcode -ne 0) {
    Write-Error "CMake exit: $lastexitcode"
    return ;
}
&cmake --build . --config "$Flavor"

Function Global:FixInstall {
    param(
        [String]$TargetDir,
        [String]$Configuration
    )
    $filelist = Get-ChildItem "$TargetDir"  -Recurse *.cmake | Foreach-Object {$_.FullName}
    foreach ($file in $filelist) {
        $content = Get-Content $file
        Clear-Content $file
        foreach ($line in $content) {
            $lr = $line.Replace("`$(Configuration)", "$Configuration")
            Add-Content $file -Value $lr
        }
    }
}

if ($lastexitcode -ne 0) {
    Write-Error "Build failed"
    return ;
}

Function Global:Update-Build {
    Invoke-Expression -Command $Global:LLVMInitializeArgs
    Set-Location "$Global:ClangbuilderRoot/out/workdir"
    &cmake --build . --config "$Global:Flavor"
    if ($Global:Install) {
        FixInstall -TargetDir "./projects/compiler-rt/lib" -Configuration $Global:Flavor
        &cpack -C "$Flavor"
    }
}


if ($Bootstrap) {
    if (!(Test-Path "$ClangbuilderRoot/out/build")) {
        mkdir -Force "$ClangbuilderRoot/out/build"
    }
    else {
        Remove-Item -Force -Recurse "$ClangbuilderRoot/out/build/*"
    }
    Set-Location "$ClangbuilderRoot/out/build"
    $env:CC = "..\build_stage0\bin\clang-cl"
    $env:CXX = "..\build_stage0\bin\clang-cl"
    $VisualCppVersionTable = @{
        "14.0" = "1900";
        "12.0" = "1800";
        "11.0" = "1700"
    };
    if ($VisualCppVersionTable.ContainsKey($InstallationVersion)) {
        $VisualCppVersion = $VisualCppVersionTable[$InstallationVersion]
    }
    else {
        $VisualCppVersion = "1910"
    }
    if ($Global:Installation -eq "15") {
        $Global:CMakeArguments += " -DLLVM_FORCE_BUILD_RUNTIME=ON"
    }
    $env:cflags = "-fmsc-version=$VisualCppVersion $ArchFlags $env:cflags"
    $env:cxxflags = "-fmsc-version=$VisualCppVersion $ArchFlags $env:cxxflags"
    &cmake $Global:CMakeArguments.Split() 
    if ($lastexitcode -ne 0) {
        exit 1
    }
    &ninja all 
    if ($lastexitcode -ne 0) {
        exit 1
    }
    if ($Package) {
        &ninja package 
        if ($lastexitcode -ne 0) {
            Write-Host "Make installation package failed "
        }
        else {
            Write-Host "Make installation package success "
        }
    }
}
else {
    if ($Package) {
        if (Test-Path "$PWD/LLVM.sln") {
            #$(Configuration)
            FixInstall -TargetDir "./projects/compiler-rt/lib" -Configuration $Flavor
            &cpack -C "$Flavor"
        }
    }
}