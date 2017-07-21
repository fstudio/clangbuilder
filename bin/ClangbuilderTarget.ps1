#!/usr/bin/env powershell

param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch = "x64",

    [ValidateSet("Release", "Debug", "MinSizeRel", "RelWithDebug")]
    [String]$Flavor = "Release",

    [ValidateSet("MSBuild", "Ninja", "NinjaBootstrap", "NinjaIterate")]
    [String]$Engine = "MSBuild",
    [String]$InstallId, # install id
    [String]$InstallationVersion, # installationVersion
    [Switch]$Environment, # start environment 
    [Switch]$Sdklow, # low sdk support
    [Switch]$LLDB,
    [Switch]$Static,
    [Switch]$Latest,
    [Switch]$Package,
    [Switch]$Libcxx,
    [Switch]$ClearEnv
)

Function Parallel() {
    $MemSize = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory
    $ProcessorCount = $env:NUMBER_OF_PROCESSORS
    $MemParallelRaw = $MemSize / 1610612736 #1.5GB
    [int]$MemParallel = [Math]::Floor($MemParallelRaw)
    if ($MemParallel -eq 0) {
        # when memory less 1.5GB, parallel use 1
        $MemParallel = 1
    }
    return [Math]::Min($ProcessorCount, $MemParallel)
}

if ($ClearEnv) {
    $env:Path = "${env:windir};${env:windir}\System32;${env:windir}\System32\Wbem;${env:windir}\System32\WindowsPowerShell\v1.0"
}

$Global:ClangbuilderRoot = Split-Path -Parent $PSScriptRoot

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
    Write-Host "Build llvm latest released version"
    $Global:LLVMSource = "$Global:ClangbuilderRoot\out\release"
}
else {
    $Global:LLVMInitializeArgs = "$Global:ClangbuilderRoot\bin\LLVMInitializeEx.ps1"
    Write-Host "Build llvm master"
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

$Global:ArchName = $ArchTable[$Arch];
$Global:ArchValue = $Arch;
# Builder CMake Arguments
$Global:Installation = $InstallationVersion.Substring(0, 2)
$Global:FinalWorkdir = ""
$Global:Flavor = $Flavor
$Global:CMakeArguments = " `"$Global:LLVMSource`""

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

$Global:CMakeArguments += " -DCMAKE_BUILD_TYPE=$Flavor  -DLLVM_APPEND_VC_REV=ON -DLLVM_ENABLE_ASSERTIONS=OFF"

if (!$Latest) {
    $Global:CMakeArguments += " -DCLANG_REPOSITORY_STRING=`"clangbuilder.io`""
}
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

Function Set-Workdir {
    param(
        [String]$Path
    )
    if (Test-Path $Path) {
        Remove-Item -Force -Recurse "$Path/*"
    }
    else {
        mkdir $Path
    }
    Set-Location $Path
}

# Please see: http://libcxx.llvm.org/docs/BuildingLibcxx.html#experimental-support-for-windows
Function Buildinglibcxx {
    $CMDClangcl = "$Global:FinalWorkdir\bin\clang-cl.exe"
    if (!(Test-Path $CMDClangcl)) {
        $CMDClangcl = "$Global:FinalWorkdir\bin\${Global:Flavor}\clang-cl.exe"
        if (!(Test-Path $CMDClangcl)) {
            return 1
        }
    }
    $Global:FinalWorkdir = "$Global:ClangbuilderRoot\out\libcxxtarget"
    Set-Workdir $Global:FinalWorkdir
    $CMakePrivateArguments = "-GNinja -DCMAKE_MAKE_PROGRAM=ninja -DCMAKE_SYSTEM_NAME=Windows"
    $CMakePrivateArguments += " -DCMAKE_C_COMPILER=`"$CMDClangcl`" -DCMAKE_CXX_COMPILER=`"$CMDClangcl`""
    $CMakePrivateArguments += " -DCMAKE_C_FLAGS=`"-fms-compatibility-version=19.00`" -DCMAKE_CXX_FLAGS=`"-fms-compatibility-version=19.00`""
    $CMakePrivateArguments += " -DLIBCXX_ENABLE_SHARED=YES -DLIBCXX_ENABLE_STATIC=YES -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=ON"
    $CMakePrivateArguments += " -DLLVM_PATH=`"${Global:LLVMSource}`""
    $CMakePrivateArguments += " ${Global:LLVMSource}\projects\libcxx"
    $pi = Start-Process -FilePath "cmake.exe" -ArgumentList $CMakePrivateArguments -NoNewWindow -Wait -PassThru
    if ($pi.ExitCode -ne 0) {
        Write-Error "CMake exit: $($pi.ExitCode)"
        return 1
    }
    $PN = & Parallel
    $pi2 = Start-Process -FilePath "ninja.exe" -ArgumentList "all -j $PN" -NoNewWindow -Wait -PassThru
    #&ninja all -j $PN
    return $pi2.ExitCode
}

Function Invoke-MSBuild {
    $Global:FinalWorkdir = "$Global:ClangbuilderRoot\out\msbuild"
    Set-Workdir $Global:FinalWorkdir
    $CMakePrivateArguments = "-G`"Visual Studio $Global:Installation $Global:ArchName`" "
    if ([System.Environment]::Is64BitOperatingSystem) {
        $CMakePrivateArguments += "-Thost=x64 ";
    }
    $CMakePrivateArguments += $Global:CMakeArguments
    Write-Host $CMakePrivateArguments
    #$CMakeArgv = $CMakePrivateArguments.Split()
    #&cmake $CMakeArgv|Write-Host
    $pi = Start-Process -FilePath "cmake.exe"-ArgumentList $CMakePrivateArguments -NoNewWindow -Wait -PassThru
    if ($pi.ExitCode -ne 0) {
        Write-Error "CMake exit: $($pi.ExitCode)"
        return 1
    }
    $pi2 = Start-Process -FilePath "cmake.exe" -ArgumentList "--build . --config $Global:Flavor" -NoNewWindow -Wait -PassThru
    return $pi2.ExitCode
}


Function Invoke-Ninja {
    $Global:FinalWorkdir = "$Global:ClangbuilderRoot\out\ninja"
    Set-Workdir $Global:FinalWorkdir
    $CMakePrivateArguments = "-GNinja -DCMAKE_INSTALL_UCRT_LIBRARIES=ON $Global:CMakeArguments"
    Write-Host $CMakePrivateArguments
    $pi = Start-Process -FilePath "cmake.exe" -ArgumentList $CMakePrivateArguments -NoNewWindow -Wait -PassThru
    if ($pi.ExitCode -ne 0) {
        Write-Error "CMake exit: $($pi.ExitCode)"
        return 1
    }
    $PN = & Parallel
    $pi2 = Start-Process -FilePath "ninja.exe" -ArgumentList "all -j $PN" -NoNewWindow -Wait -PassThru
    #&ninja all -j $PN
    return $pi2.ExitCode
    #return $lastexitcode
}


Function Get-PrecompiledLLVM {
    # get 
    $PrecompiledJSON = "$Global:ClangbuilderRoot\config\precompiled.json"
    if (!(Test-Path $PrecompiledJSON)) {
        return ""
    }
    $LLVMJSON = Get-Content -Path $PrecompiledJSON |ConvertFrom-Json
    if ($null -eq $LLVMJSON.LLVM) {
        return ""
    }
    $LLVMObj = $LLVMJSON.LLVM
    if ($null -eq $LLVMObj.Path) {
        return ""
    }
    return $LLVMObj.Path
}

Function Invoke-NinjaIterate {
    $VisualCppVersionTable = @{
        "15.0" = "19.10";
        "14.0" = "19.00";
        "12.0" = "18.00";
        "11.0" = "17.00"
    };
    $ClangMarchArgument = @{
        "x64"   = "-m64";
        "x86"   = "-m32";
        "ARM"   = "--target=arm-pc-windows-msvc -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1";
        "ARM64" = "--target=arm64-pc-windows-msvc -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1"
    }
    # 
    $PrecompiledLLVM = &Get-PrecompiledLLVM
    if ($PrecompiledLLVM -eq "") {
        return 1
    }
    if (!(Test-Path $PrecompiledLLVM)) {
        Write-Host "$PrecompiledLLVM not exists"
        return 1
    }
    $MarchArgument = $ClangMarchArgument[$Global:ArchValue]
    $env:CC = "$PrecompiledLLVM\bin\clang-cl.exe"
    $env:CXX = "$PrecompiledLLVM\bin\clang-cl.exe"
    Write-Host "update env:CC env:CXX ${env:CC} ${env:CXX}"
    $Global:FinalWorkdir = "$Global:ClangbuilderRoot\out\precompile"
    Set-Workdir $Global:FinalWorkdir
    $CMakePrivateArguments = "-GNinja $Global:CMakeArguments"
    if ($VisualCppVersionTable.ContainsKey($InstallationVersion)) {
        $VisualCppVersion = $VisualCppVersionTable[$InstallationVersion]
    }
    else {
        $VisualCppVersion = "19.00"
    }
    $CMakePrivateArguments += " -DCMAKE_C_FLAGS=`"-fms-compatibility-version=${VisualCppVersion} $MarchArgument`""
    $CMakePrivateArguments += " -DCMAKE_CXX_FLAGS=`"-fms-compatibility-version=${VisualCppVersion} $MarchArgument`""
    if ($Global:Installation -eq "14" -or ($Global:Installation -eq "15")) {
        $CMakePrivateArguments += " -DLLVM_FORCE_BUILD_RUNTIME=ON -DLIBCXX_ENABLE_SHARED=YES"
        $CMakePrivateArguments += " -DLIBCXX_ENABLE_STATIC=YES -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=ON"
        #$CMakePrivateArguments += " -DLIBCXX_ENABLE_FILESYSTEM=ON"
    }
    Write-Host $CMakePrivateArguments
    $pi = Start-Process -FilePath "cmake.exe" -ArgumentList $CMakePrivateArguments -NoNewWindow -Wait -PassThru
    if ($pi.ExitCode -ne 0) {
        Write-Error "CMake exit: $($pi.ExitCode)"
        return 1
    }
    $PN = & Parallel
    Write-Host "Now build llvm ..."
    $pi = Start-Process -FilePath "ninja.exe" -ArgumentList "all -j $PN" -NoNewWindow -Wait -PassThru
    return $pi.ExitCode
}

Function Invoke-NinjaBootstrap {
    $result = &Invoke-Ninja
    if ($result -ne 0) {
        Write-Error "Prebuild due to error terminated !"
        return $result
    }
    #$CMDClangcl = "$Global:FinalWorkdir\bin\clang-cl.exe"
    $VisualCppVersionTable = @{
        "15.0" = "19.10";
        "14.0" = "19.00";
        "12.0" = "18.00";
        "11.0" = "17.00"
    };
    $env:CC = "$Global:FinalWorkdir\bin\clang-cl.exe"
    $env:CXX = "$Global:FinalWorkdir\bin\clang-cl.exe"
    Write-Host "update env:CC env:CXX ${env:CC} ${env:CXX}"
    $Global:FinalWorkdir = "$Global:ClangbuilderRoot\out\bootstrap"
    Set-Workdir $Global:FinalWorkdir
    $CMakePrivateArguments = "-GNinja $Global:CMakeArguments"
    #$CMakePrivateArguments += " -DCMAKE_C_COMPILER=`"$CMDClangcl`" -DCMAKE_CXX_COMPILER=`"$CMDClangcl`""
    if ($VisualCppVersionTable.ContainsKey($InstallationVersion)) {
        $VisualCppVersion = $VisualCppVersionTable[$InstallationVersion]
    }
    else {
        $VisualCppVersion = "19.00"
    }
    $CMakePrivateArguments += " -DCMAKE_C_FLAGS=`"-fms-compatibility-version=${VisualCppVersion}`""
    $CMakePrivateArguments += " -DCMAKE_CXX_FLAGS=`"-fms-compatibility-version=${VisualCppVersion}`""
    if ($Global:Installation -eq "14" -or ($Global:Installation -eq "15")) {
        $CMakePrivateArguments += " -DLLVM_FORCE_BUILD_RUNTIME=ON -DLIBCXX_ENABLE_SHARED=YES"
        $CMakePrivateArguments += " -DLIBCXX_ENABLE_STATIC=YES -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=ON"
        #$CMakePrivateArguments += " -DLIBCXX_ENABLE_FILESYSTEM=ON"
    }
    Write-Host $CMakePrivateArguments
    $pi = Start-Process -FilePath "cmake.exe" -ArgumentList $CMakePrivateArguments -NoNewWindow -Wait -PassThru
    if ($pi.ExitCode -ne 0) {
        Write-Error "CMake exit: $($pi.ExitCode)"
        return 1
    }
    Write-Host "Begin to compile llvm..."
    $PN = & Parallel
    $pi = Start-Process -FilePath "ninja.exe" -ArgumentList "all -j $PN" -NoNewWindow -Wait -PassThru
    return $pi.ExitCode
}


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

Function Global:Update-Build {
    Invoke-Expression -Command $Global:LLVMInitializeArgs
    Set-Location "$Global:ClangbuilderRoot/out/workdir"
    $pi = Start-Process cmake -ArgumentList "--build . --config $Global:Flavor" -NoNewWindow -Wait -PassThru
    if ($Global:Install -and $pi.ExitCode -eq 0) {
        FixInstall -TargetDir "./projects/compiler-rt/lib" -Configuration $Global:Flavor
        Start-Process -FilePath "cpack.exe" -ArgumentList "-C $Global:Flavor" -NoNewWindow -Wait -PassThru
    }
}

$MyResult = -1

switch ($Engine) {
    {$_ -eq "MSBuild"} {
        Write-Host "Build LLVM use MSBuild"
        $MyResult = &Invoke-MSBuild
    } {$_ -eq "Ninja"} {
        Write-Host "Build LLVM use Ninja"
        $MyResult = &Invoke-Ninja
    } {$_ -eq "NinjaBootstrap"} {
        Write-Host "Build Bootstrap Ninja"
        $MyResult = &Invoke-NinjaBootstrap
    } {$_ -eq "NinjaIterate"} {
        $MyResult = &Invoke-NinjaIterate
    }
}

if ($MyResult -ne 0) {
    Write-Error "Engine: $Engine, Result: $MyResult"
    return ;
}
else {
    Write-Host "Build LLVM/Clang Success"
}



if ($Package) {
    if (Test-Path "$PWD/LLVM.sln") {
        #$(Configuration)
        FixInstall -TargetDir "./projects/compiler-rt/lib" -Configuration $Flavor
    }
    &cpack -C "$Flavor"
}

if ($Libcxx -and ($Engine -ne "NinjaBootstrap")) {
    $MylibcxxResult = &Buildinglibcxx
    if ($MylibcxxResult -eq 0) {
        &cpack -C "$Flavor"
    }
}

Write-Host "You can run Update-Build"