#!/usr/bin/env powershell
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch = "x64",
    [ValidateSet("Release", "Debug", "MinSizeRel", "RelWithDebug")]
    [String]$Flavor = "Release",
    [ValidateSet("MSBuild", "Ninja", "NinjaBootstrap", "NinjaIterate")]
    [String]$Engine = "MSBuild",
    [ValidateSet("Mainline", "Stable", "Release")]
    [String]$Branch = "Mainline", #mainline 
    [String]$InstanceId, # install id
    [String]$InstallationVersion, # installationVersion
    [Switch]$Environment, # start environment 
    [Switch]$Sdklow, # low sdk support
    [Switch]$LLDB,
    [Switch]$Static,
    [Switch]$Package,
    [Switch]$ClearEnv
)

# On Windows, Start-Process -Wait will wait job process, obObject.WaitOne(_waithandle);
# Don't use it
Function ProcessExec {
    param(
        [string]$FilePath,
        [string]$Arguments,
        [string]$WorkingDirectory
    )
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo 
    $ProcessInfo.FileName = $FilePath
    Write-Host "$FilePath $Arguments $PWD"
    if ($WorkingDirectory.Length -eq 0) {
        $ProcessInfo.WorkingDirectory = $PWD
    }
    else {
        $ProcessInfo.WorkingDirectory = $WorkingDirectory
    }
    $ProcessInfo.Arguments = $Arguments
    $ProcessInfo.UseShellExecute = $false ## use createprocess not shellexecute
    $Process = New-Object System.Diagnostics.Process 
    $Process.StartInfo = $ProcessInfo 
    if ($Process.Start() -eq $false) {
        return -1
    }
    $Process.WaitForExit()
    return $Process.ExitCode
}

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

$VisualStudioArgs = $null
if ($InstanceId -eq "VisualCppTools") {
    if ($Engine -eq "MSbuild" -and $Environment -eq $false) {
        Write-Host -ForegroundColor Red "VisualCppTools Not support msbuild !"
        exit 1
    }
    $VisualStudioArgs = "$PSScriptRoot/VisualCppToolsEnv.ps1 -Arch $Arch -InstanceId $InstanceId"
}
else {
    $VisualStudioArgs = "$PSScriptRoot/VisualStudioEnvinitEx.ps1 -Arch $Arch -InstanceId $InstanceId"
}



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
else {
    Update-Title -Title " [Build: $Branch]"
}

# LLVM get from subversion
Function ParseLLVMDir {
    $obj = Get-Content -Path "$ClangbuilderRoot/config/revision.json" |ConvertFrom-Json
    switch ($Branch) {
        {$_ -eq "Mainline"} {
            $src = "$Global:ClangbuilderRoot\out\mainline"
        } {$_ -eq "Stable"} {
            $currentstable = $obj.Stable
            $src = "$Global:ClangbuilderRoot\out\$currentstable"
        } {$_ -eq "Release"} {
            $src = "$Global:ClangbuilderRoot\out\rel\llvm"
        }
    }
    return $src
}

$Global:LLDB = $LLDB
if ($Branch -eq "Release") {
    $Global:LLVMInitializeArgs = "$Global:ClangbuilderRoot\bin\LLVMDownload.ps1"
    Write-Host "Build llvm release"
    $Global:LLVMSource = "$Global:ClangbuilderRoot\out\rel\llvm"
}
else {
    $Global:LLVMInitializeArgs = "$Global:ClangbuilderRoot\bin\LLVMRemoteFetch.ps1 -Branch $Branch"
    Write-Host "Build llvm branch $Branch"
    $Global:LLVMSource = &ParseLLVMDir
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
$Global:CMakeArguments = "`"$Global:LLVMSource`""

if ($LLDB) {
    . "$PSScriptRoot\LLDBInitialize.ps1"
    $PythonHome = Get-Pyhome -Arch $Arch
    if ($null -eq $PythonHome) {
        Write-Error "Please Install Python 3.5+ ! "
        Exit 
    }
    Write-Host -ForegroundColor Yellow "Building LLVM with lldb,$Engine, $VisualStudioTarget"
    $Global:CMakeArguments += " -DPYTHON_HOME=$PythonHome -DLLDB_RELOCATABLE_PYTHON=1"
}

$Global:CMakeArguments += " -DCMAKE_BUILD_TYPE=$Flavor  -DLLVM_ENABLE_ASSERTIONS=OFF"

if ($Branch -eq "Mainline") {
    $Global:CMakeArguments += " -DLLVM_APPEND_VC_REV=ON"
}
else {
    $Global:CMakeArguments += " -DLLVM_APPEND_VC_REV=OFF -DCLANG_REPOSITORY_STRING=`"clangbuilder.io`""
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
        Remove-Item -Force -Recurse "$Path"
    }
    New-Item -ItemType Directory $Path |Out-Null
    Set-Location $Path
}

# Please see: http://libcxx.llvm.org/docs/BuildingLibcxx.html#experimental-support-for-windows

Function Invoke-MSBuild {
    $Global:FinalWorkdir = "$Global:ClangbuilderRoot\out\msbuild"
    Set-Workdir $Global:FinalWorkdir
    if ($Global:ArchName.Length -eq 0) {
        $CMakePrivateArguments = "-G`"Visual Studio $Global:Installation`" "
    }
    else {
        $CMakePrivateArguments = "-G`"Visual Studio $Global:Installation $Global:ArchName`" "
    }

    if ([System.Environment]::Is64BitOperatingSystem) {
        $CMakePrivateArguments += "-Thost=x64 ";
    }
    $CMakePrivateArguments += $Global:CMakeArguments
    $exitcode = ProcessExec  -FilePath "cmake" -Arguments $CMakePrivateArguments 
    if ($exitcode -ne 0) {
        Write-Error "CMake exit: $exitcode"
        return 1
    }
    $exitcode = ProcessExec -FilePath "cmake" -Arguments "--build . --config $Global:Flavor" 
    return $exitcode
}

Function Invoke-Ninja {
    $Global:FinalWorkdir = "$Global:ClangbuilderRoot\out\ninja"
    Set-Workdir $Global:FinalWorkdir
    $CMakePrivateArguments = "-GNinja $Global:CMakeArguments -DCMAKE_INSTALL_UCRT_LIBRARIES=ON"
    ### change oe
    $oe=[Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 ### Ninja need UTF8
    $exitcode = ProcessExec  -FilePath "cmake.exe" -Arguments $CMakePrivateArguments 
    if ($exitcode -ne 0) {
        Write-Error "CMake exit: $exitcode"
        return 1
    }
    $PN = & Parallel
    [Console]::OutputEncoding=$oe
    $exitcode = ProcessExec  -FilePath "ninja.exe" -Arguments "all -j $PN"
    return $exitcode
}

Function Get-PrebuiltLLVM {
    $PrebuiltJSON = "$Global:ClangbuilderRoot\config\prebuilt.json"
    if (!(Test-Path $PrebuiltJSON)) {
        return ""
    }
    $LLVMJSON = Get-Content -Path $PrebuiltJSON |ConvertFrom-Json
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
    $PrebuiltLLVM = &Get-PrebuiltLLVM
    if ($PrebuiltLLVM -eq "") {
        return 1
    }
    if (!(Test-Path $PrebuiltLLVM)) {
        Write-Host "$PrebuiltLLVM not exists"
        return 1
    }
    $MarchArgument = $ClangMarchArgument[$Global:ArchValue]
    $env:CC = "$PrebuiltLLVM\bin\clang-cl.exe"
    $env:CXX = "$PrebuiltLLVM\bin\clang-cl.exe"
    Write-Host "update `$env:CC `$env:CXX ${env:CC} ${env:CXX}"
    $Global:FinalWorkdir = "$Global:ClangbuilderRoot\out\prebuilt"
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

    $oe=[Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 ### Ninja need UTF8
    $exitcode = ProcessExec  -FilePath "cmake.exe" -Arguments $CMakePrivateArguments 
    if ($exitcode -ne 0) {
        Write-Error "CMake exit: $exitcode"
        return 1
    }
    $PN = & Parallel
    Write-Host "Build llvm, $Engine $Arch $Branch"
    [Console]::OutputEncoding=$oe
    $exitcode = ProcessExec -FilePath "ninja.exe" -Arguments "all -j $PN"
    return $exitcode
}

Function Invoke-NinjaBootstrap {
    $result = &Invoke-Ninja
    if ($result -ne 0) {
        Write-Error "Prebuild llvm due to error terminated !"
        return $result
    }
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

    $oe=[Console]::OutputEncoding
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 ### Ninja need UTF8
    $exitcode = ProcessExec  -FilePath "cmake.exe" -Arguments $CMakePrivateArguments 
    if ($exitcode -ne 0) {
        Write-Error "CMake exit: $exitcode"
        return 1
    }
    Write-Host "Build llvm, $Engine $Arch $Branch"
    [Console]::OutputEncoding=$oe
    $PN = & Parallel
    $exitcode = ProcessExec -FilePath "ninja.exe" -Arguments "all -j $PN"
    return $exitcode
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

Write-Host "Use llvm build engine: $Engine"
$MyResult = -1


switch ($Engine) {
    "MSBuild" {
        $MyResult = Invoke-MSBuild
    }
    "Ninja" {
        $MyResult = Invoke-Ninja
    }
    "NinjaBootstrap" {
        $MyResult = Invoke-NinjaBootstrap
    }"NinjaIterate" {
        $MyResult = Invoke-NinjaIterate
    }
}


if ($MyResult -ne 0) {
    Write-Host -ForegroundColor Red "Engine: $Engine, Result: $MyResult"
    return ;
}
else {
    Write-Host "Build llvm completed, your can run cpack"
}

if ($Package) {
    if (Test-Path "$PWD/LLVM.sln") {
        FixInstall -TargetDir "./projects/compiler-rt/lib" -Configuration $Flavor
    }
    &cpack -C "$Flavor"
}


Write-Host "compile llvm done, you can use it"

