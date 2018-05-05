#!/usr/bin/env pwsh
param (
    [Parameter(Position = 0)]
    [Alias("id")]
    [String]$InstanceId, # install id
    [String]$InstallationVersion, # installationVersion
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch = "x64",
    [ValidateSet("Release", "Debug", "MinSizeRel", "RelWithDebug")]
    [String]$Flavor = "Release",
    [ValidateSet("MSBuild", "Ninja", "NinjaBootstrap", "NinjaIterate")]
    [String]$Engine = "MSBuild",
    [ValidateSet("Mainline", "Stable", "Release")]
    [String]$Branch = "Mainline", #mainline 
    [Alias("e")]
    [Switch]$Environment, # start environment 
    [Switch]$Sdklow, # low sdk support
    [Switch]$LLDB,
    [Switch]$LTO,
    [Switch]$Package,
    [Switch]$ClearEnv
)
."$PSScriptRoot\ProfileEnv.ps1"

Import-Module -Name "$ClangbuilderRoot\modules\Initialize"
Import-Module -Name "$ClangbuilderRoot\modules\Utils"
Import-Module -Name "$ClangbuilderRoot\modules\CMake"
Import-Module -Name "$ClangbuilderRoot\modules\VisualStudio"
Import-Module -Name "$ClangbuilderRoot\modules\Devi" # Package Manager


# Cleanup $env:PATH, because, some tools modify Disrupt PATH

if ($ClearEnv) {
    # ReinitializePath
    ReinitializePath
}

$ret = DevinitializeEnv -ClangbuilderRoot $ClangbuilderRoot -Pkglocksdir $Pkglocksdir
if ($ret -ne 0) {
    exit 1
}

Function ExecuteExists{
    param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Enter Execute Name")]
        [ValidateNotNullorEmpty()]
        [String]$Command
    )
    $cmd=Get-Command -CommandType Application $Command -ErrorAction SilentlyContinue
    if($cmd -eq $null){
        return $false
    }
    return $true
}

if ((Test-Path Alias:curl) -and (ExecuteExists "curl.exe")) {
    Remove-Item Alias:curl
}

if ((Test-Path Alias:wget) -and (ExecuteExists "wget.exe")) {
    Remove-Item Alias:wget
}


if ($InstanceId.Length -eq 0) {
    $InstallationVersion = "15.0"
    $ret = DefaultVisualStudio -ClangbuilderRoot $ClangbuilderRoot -Arch $Arch
}
else {
    $ret = InitializeVisualStudio -ClangbuilderRoot $ClangbuilderRoot -Arch $Arch -InstanceId $InstanceId -Sdklow:$Sdklow
}
if ($InstallationVersion.Length -eq 0) {
    if ($InstanceId.StartsWith("VisualStudio.")) {
        $InstallationVersion = $InstanceId.Split("VisualStudio.".Length)
    }
    else {
        $InstallationVersion = "15.0"
    }
}
if ($ret -ne 0 -or $InstallationVersion.Length -lt 3) {
    Write-Host -ForegroundColor Red "Not found valid installed visual studio. $InstallationVersion"
    exit 1
}

InitializeExtranl -ClangbuilderRoot $ClangbuilderRoot -Arch $Arch
InitializeEnv -ClangbuilderRoot $ClangbuilderRoot

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
    $obj = Get-Content -Path "$ClangbuilderRoot\config\revision.json" |ConvertFrom-Json
    switch ($Branch) {
        {$_ -eq "Mainline"} {
            $src = "$ClangbuilderRoot\out\mainline"
        } {$_ -eq "Stable"} {
            $currentstable = $obj.Stable
            $src = "$ClangbuilderRoot\out\$currentstable"
        } {$_ -eq "Release"} {
            $src = "$ClangbuilderRoot\out\rel\llvm"
        }
    }
    return $src
}


$LLVMSource = &ParseLLVMDir

Write-Host "Select LLVM $Branch, sources dir: $LLVMSource"

$LLVMScript = "$ClangbuilderRoot\bin\LLVMRemoteFetch.ps1"
if ($Branch -eq "Release") {
    $LLVMScript = "$ClangbuilderRoot\bin\LLVMDownload.ps1"
}


# Update LLVM sources
Invoke-Expression "$LLVMScript -Branch $Branch -LLDB:`$LLDB"

$ArchTable = @{
    "x86"   = "";
    "x64"   = "Win64";
    "ARM"   = "ARM";
    "ARM64" = "ARM64"
}

$ArchName = $ArchTable[$Arch];


# Builder CMake Arguments

$Installation = $InstallationVersion.Substring(0, 2)
$Global:LatestBuildDir = ""
$CMakeArguments = "`"$LLVMSource`""

if ($LLDB) {
    $CMakeArguments += " -DLLDB_RELOCATABLE_PYTHON=1 -DLLDB_DISABLE_PYTHON=1"
}

$CMakeArguments += " -DCMAKE_BUILD_TYPE=$Flavor   -DLLVM_ENABLE_ASSERTIONS=OFF"
$CMakeArguments += " -DCMAKE_INSTALL_UCRT_LIBRARIES=ON "

if ($Branch -eq "Mainline") {
    $CMakeArguments += " -DLLVM_APPEND_VC_REV=ON"
}
else {
    $CMakeArguments += " -DLLVM_APPEND_VC_REV=OFF -DCLANG_REPOSITORY_STRING=`"clangbuilder.io`""
}

$CMakeArguments += CMakeCustomflags -ClangbuilderRoot $ClangbuilderRoot -Branch $Branch


# -DLLVM_ENABLE_LIBCXX=ON -DLLVM_ENABLE_MODULES=ON -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON

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

Function Get-ClangArgument {
    # Parse clang args
    # $ver=(Get-Item $clexe|Select-Object -ExpandProperty VersionInfo|Select-Object -Property FileVersion)
    # https://github.com/llvm-mirror/clang/blob/6c57331175c84f06b8adbae858043ab5c782355f/lib/Driver/ToolChains/MSVC.cpp#L1269
    
    $msvc = "19.12"
    try {
        $clexe = Get-Command -CommandType Application "cl.exe"
        $msvc = "$($clexe.FileVersionInfo.FileMajorPart).$($clexe.FileVersionInfo.FileMinorPart)"
    }
    catch {
        $VisualCppVersionTable = @{
            "15" = "19.14";
            "14" = "19.00";
            "12" = "18.00";
            "11" = "17.00"
        };
    
        if ($VisualCppVersionTable.ContainsKey($Global:Installation)) {
            $msvc = $VisualCppVersionTable[$Installation]
        }
    }

    Write-Host "Detecting: -fms-compatibility-version=$msvc "
    $ClangMarchArgument = @{
        "x64"   = "-m64";
        "x86"   = "-m32";
        "ARM"   = "--target=arm-pc-windows-msvc -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1";
        "ARM64" = "--target=arm64-pc-windows-msvc -D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1"
    }
    $ClangArgs = $ClangMarchArgument[$Arch]
    $Arguments = "-GNinja $Global:CMakeArguments"
    $CompilerFlags = "-fms-compatibility-version=$msvc $ClangArgs"

    $Arguments += " -DCMAKE_C_FLAGS=`"$CompilerFlags`""
    $Arguments += " -DCMAKE_CXX_FLAGS=`"$CompilerFlags`""
    if ($Installation -eq "14" -or ($Installation -eq "15")) {
        $Arguments += " -DLLVM_FORCE_BUILD_RUNTIME=ON -DLIBCXX_ENABLE_SHARED=YES"
        $Arguments += " -DLIBCXX_ENABLE_STATIC=YES -DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=ON"
        #$Arguments += " -DLIBCXX_ENABLE_FILESYSTEM=ON"
        $Arguments += " -DLIBCXX_HAS_WIN32_THREAD_API=ON -DLIBCXX_NO_VCRUNTIME=ON"
    }
    return $Arguments
}

Function ClangNinjaGenerator {
    param(
        [String]$ClangExe,
        [String]$BuildDir
    )
    $env:CC = $ClangExe
    $env:CXX = $ClangExe

    Write-Host "Build llvm, Use: CC=$env:CC CXX=$env:CXX"

    $Global:LatestBuildDir = $BuildDir
    Set-Workdir $Global:LatestBuildDir
    $Arguments = Get-ClangArgument
    if ($LTO) {
        try {
            $ClangbinDir = (Split-Path  -Path (Get-Item $ClangExe).FullName).Replace("\","/")
            # https://clang.llvm.org/docs/ThinLTO.html#clang-bootstrap
            $Arguments += " -DLLVM_ENABLE_LTO=Thin `"-DCMAKE_LINKER=$ClangbinDir/lld-link.exe`""
            $Arguments += " `"-DCMAKE_AR=$ClangbinDir/llvm-ar.exe`" `"-DCMAKE_RANLIB=$ClangbinDir/llvm-ranlib.exe`""
        }
        catch {
            Write-Host "$_"
        }
        Write-Host -ForegroundColor Cyan "To bootstrap clang/LLVM with ThinLTO"
    }
    $exitcode = ProcessExec  -FilePath "cmake.exe" -Arguments $Arguments
    if ($exitcode -ne 0) {
        Write-Error "CMake exit: $exitcode"
        return 1
    }
    $PN = & Parallel
    $exitcode = ProcessExec -FilePath "ninja.exe" -Arguments "all -j $PN"
    return $exitcode
}


# Please see: http://libcxx.llvm.org/docs/BuildingLibcxx.html#experimental-support-for-windows

Function Invoke-MSBuild {
    $Global:LatestBuildDir = "$ClangbuilderRoot\out\msbuild"
    Set-Workdir $Global:LatestBuildDir
    if($LTO){
        
    }
    if ($ArchName.Length -eq 0) {
        $Arguments = "-G`"Visual Studio $Installation`" "
    }
    else {
        $Arguments = "-G`"Visual Studio $Installation $ArchName`" "
    }
    if ([System.Environment]::Is64BitOperatingSystem) {
        $Arguments += "-Thost=x64 ";
    }
    $Arguments += $CMakeArguments
    $exitcode = ProcessExec  -FilePath "cmake" -Arguments $Arguments 
    if ($exitcode -ne 0) {
        Write-Error "CMake exit: $exitcode"
        return 1
    }
    $exitcode = ProcessExec -FilePath "cmake" -Arguments "--build . --config $Flavor" 
    return $exitcode
}

Function Invoke-Ninja {
    $Global:LatestBuildDir = "$ClangbuilderRoot\out\ninja"
    Set-Workdir $Global:LatestBuildDir
    $Arguments = "-GNinja $CMakeArguments"
    ### change oe
    ## ARM64 can build Desktop App, but ARM not
    if ($Arch -eq "ARM") {
        Write-Host -ForegroundColor Yellow "Warning: Build LLVM Maybe failed."
        $Arguments += " -DCMAKE_C_FLAGS=`"-D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1`""
        $Arguments += " -DCMAKE_CXX_FLAGS=`"-D_ARM_WINAPI_PARTITION_DESKTOP_SDK_AVAILABLE=1`""
    }
    #$oe = [Console]::OutputEncoding
    #[Console]::OutputEncoding = [System.Text.Encoding]::UTF8 ### Ninja need UTF8
    $exitcode = ProcessExec  -FilePath "cmake.exe" -Arguments $Arguments 
    if ($exitcode -ne 0) {
        Write-Error "CMake exit: $exitcode"
        return 1
    }
    $PN = & Parallel
    #[Console]::OutputEncoding = $oe
    $exitcode = ProcessExec  -FilePath "ninja.exe" -Arguments "all -j $PN"
    return $exitcode
}

Function Get-PrebuiltLLVM {
    $PrebuiltJSON = "$ClangbuilderRoot\config\prebuilt.json"
    if (!(Test-Path $PrebuiltJSON)) {
        Write-Host "$PrebuiltJSON dose not exists, use prebuilt.template.json"
        $PrebuiltJSON = "$ClangbuilderRoot\config\prebuilt.template.json"
        if (!(Test-Path $PrebuiltJSON)) {
            return ""
        }
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

# Need Set MSVC flags -fms-compatibility-version=xx.xx
Function Invoke-NinjaIterate {
    $PrebuiltLLVM = &Get-PrebuiltLLVM
    if ($PrebuiltLLVM -eq "") {
        return 1
    }
    if (!(Test-Path $PrebuiltLLVM)) {
        Write-Host "$PrebuiltLLVM not exists"
        return 1
    }
    $exitcode = ClangNinjaGenerator -ClangExe "$PrebuiltLLVM\bin\clang-cl.exe" -BuildDir "$ClangbuilderRoot\out\prebuilt"
    return $exitcode
}

Function Invoke-NinjaBootstrap {
    $result = &Invoke-Ninja
    if ($result -ne 0) {
        Write-Error "Prebuild llvm due to error terminated !"
        return $result
    }
    $exitcode = ClangNinjaGenerator -ClangExe "$Global:LatestBuildDir\bin\clang-cl.exe" -BuildDir  "$ClangbuilderRoot\out\bootstrap"

    return $exitcode
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
    }
    "NinjaIterate" {
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

$Libcxxbin = "$Global:LatestBuildDir\lib\c++.dll"
$CMakeInstallFile = "$Global:LatestBuildDir\cmake_install.cmake"
if (Test-Path $Libcxxbin) {
    $Libcxxbin = $Libcxxbin.Replace('\', '/')
    "file(INSTALL DESTINATION `"`${CMAKE_INSTALL_PREFIX}/bin`" TYPE SHARED_LIBRARY OPTIONAL FILES `"$Libcxxbin`")"|Out-File -FilePath $CMakeInstallFile -Append -Encoding utf8
}

if ($Package) {
    if (Test-Path "$PWD/LLVM.sln") {
        CMakeInstallationFix -TargetDir "./projects/compiler-rt/lib" -Configuration $Flavor
    }
    &cpack -C "$Flavor"
}


Write-Host "compile llvm done, you can use it"

