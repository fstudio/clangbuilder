<#############################################################################
#  ClangBuilderManager.ps1
#  Note: Clang Auto Build TaskScheduler
#  Date:2016 01
#  Author:Force <forcemz@outlook.com>
##############################################################################>
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch="x64",

    [ValidateSet("Release", "Debug", "MinSizeRel", "RelWithDebug")]
    [String]$Flavor = "Release",

    [ValidateSet("110", "120", "140", "141", "150")]
    [String]$VisualStudio="120",
    [Switch]$LLDB,
    [Switch]$Static,
    [Switch]$NMake,
    [Switch]$Released,
    [Switch]$Install,
    [Switch]$Clear
)

. "$PSScriptRoot/Initialize.ps1"

Update-Title -Title " [Building]"

$ClangbuilderRoot=Split-Path -Parent $PSScriptRoot


$Sdklow=$false
$VS="14.0"

switch($VisualStudio){ {$_ -eq "110"}{
        $VS="11.0"
    }{$_ -eq "120"}{
        $VS="12.0"
    }{$_ -eq "140"}{
        $Sdklow=$true
        $VS="14.0"
    } {$_ -eq "141"}{
        $VS="14.0"
    } {$_ -eq "150"}{
        $Sdklow=$true
        $VS="15.0"
    } {$_ -eq "151"}{
        $VS="15.0"
    }
}

if($Clear){
    Reset-Environment
}

Invoke-Expression -Command "$PSScriptRoot/PathLoader.ps1"
if($Sdklow){
    Invoke-Expression -Command "$PSScriptRoot/VisualStudioEnvinit.ps1 -Arch $Arch -VisualStudio $VS -Sdklow"
}else{
    Invoke-Expression -Command "$PSScriptRoot/VisualStudioEnvinit.ps1 -Arch $Arch -VisualStudio $VS"
}


if($Released){
    $SourcesDir="release"
    Write-Output "Build last released revision"
    if($LLDB){
        Invoke-Expression -Command "$PSScriptRoot\LLVMInitialize.ps1 -LLDB" 
    }else{
        Invoke-Expression -Command "$PSScriptRoot\LLVMInitialize.ps1" 
    }
}else{
    $SourcesDir="mainline"
    Write-Output "Build trunk branch"
    if($LLDB){
        Invoke-Expression -Command "$PSScriptRoot\LLVMInitialize.ps1 -LLDB -Mainline" 
    }else{
        Invoke-Expression -Command "$PSScriptRoot\LLVMInitialize.ps1 -Mainline" 
    }
}

if(!(Test-Path "$ClangbuilderRoot/out/workdir")){
    mkdir -Force "$ClangbuilderRoot/out/workdir"
}else{
    Remove-Item -Force -Recurse "$ClangbuilderRoot/out/workdir/*"
}

Set-Location "$ClangbuilderRoot/out/workdir"

if($Static){
    $CRTLinkRelease="MT"
    $CRTLinkDebug="MTd"
}else{
    $CRTLinkRelease="MD"
    $CRTLinkDebug="MDd"
}


Function Start-NMakeBuilder{
    $NumberOfLogicalProcessors=(Get-WmiObject Win32_Processor).NumberOfLogicalProcessors
    Write-Output "Number Of Logical Processor: $NumberOfLogicalProcessors"
    cmake "..\$SourcesDir" -G"NMake Makefiles" -DCMAKE_CONFIGURATION_TYPES="$Flavor" -DCMAKE_BUILD_TYPE="$Flavor"  -DLLVM_ENABLE_ASSERTIONS=ON -DLLVM_USE_CRT_RELEASE="$CRTLinkRelease" -DLLVM_USE_CRT_MINSIZEREL="$CRTLinkRelease" -DLLVM_APPEND_VC_REV=ON
    if(Test-Path "Makefile"){
         &cmake --build . --config "$Flavor"
    }
}


Function Start-MSBuild{
    Write-Host "Use Visual Studio $VSTools $Arch"
    if($Arch -eq "x64"){
        &cmake "..\$SourcesDir" -G "Visual Studio $VSTools Win64" -DCMAKE_CONFIGURATION_TYPES="$Flavor"  -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_BUILD_TYPE="$Flavor" -DLLVM_USE_CRT_RELEASE="$CRTLinkRelease" -DLLVM_USE_CRT_MINSIZEREL="$CRTLinkRelease" -DLLVM_APPEND_VC_REV=ON
        if(Test-Path "LLVM.sln"){
            #&msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration="$Flavor" /p:Platform=x64 /t:ALL_BUILD
            &cmake --build . --config "$Flavor"
        }

    }elseif($Arch -eq "ARM"){
        &cmake "..\$SourcesDir" -G "Visual Studio $VSTools ARM" -DCMAKE_CONFIGURATION_TYPES="$Flavor"  -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_BUILD_TYPE="$Flavor" -DLLVM_USE_CRT_RELEASE="$CRTLinkRelease" -DLLVM_USE_CRT_MINSIZEREL="$CRTLinkRelease" -DLLVM_APPEND_VC_REV=ON
        if(Test-Path "LLVM.sln"){
            #&msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration="$Flavor" /p:Platform=ARM /t:ALL_BUILD
            &cmake --build . --config "$Flavor"
        }

    }elseif($Arch -eq "ARM64" -and $VisualStudio -ge 141){
        &cmake "..\$SourcesDir" -G "Visual Studio $VSTools ARM64" -DCMAKE_CONFIGURATION_TYPES="$Flavor" -DLLVM_ENABLE_ASSERTIONS=ON  -DCMAKE_BUILD_TYPE="$Flavor" -DLLVM_USE_CRT_RELEASE="$CRTLinkRelease" -DLLVM_USE_CRT_MINSIZEREL="$CRTLinkRelease" -DLLVM_APPEND_VC_REV=ON
        if(Test-Path "LLVM.sln"){
            #&msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration=$Flavor /p:Platform=ARM64 /t:ALL_BUILD
            &cmake --build . --config "$Flavor"
        }
    }else{
        &cmake "..\$SourcesDir" -G "Visual Studio $VSTools" -DCMAKE_CONFIGURATION_TYPES="$Flavor"  -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_BUILD_TYPE="$Flavor" -DLLVM_USE_CRT_RELEASE="$CRTLinkRelease" -DLLVM_USE_CRT_MINSIZEREL="$CRTLinkRelease" -DLLVM_APPEND_VC_REV=ON
        if(Test-Path "LLVM.sln"){
            #&msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration="$Flavor" /p:Platform=win32 /t:ALL_BUILD
            &cmake --build . --config "$Flavor"
        }
    }
}

Function Start-MSbuildAddLLDB{
    . "$PSScriptRoot\LLDBInitialize.ps1"
    $PythonHome=Get-Pyhome -Arch $Arch
    if($null -eq $PythonHome){
        Write-Error "Not Found python 3.5 or later install on your system ! "
        Exit 
    }
    if($Arch -eq "x64"){
        &cmake "..\$SourcesDir" -GNinja -DPYTHON_HOME="$PythonHome" -DLLDB_RELOCATABLE_PYTHON=1  -DCMAKE_CONFIGURATION_TYPES="$Flavor"  -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_BUILD_TYPE="$Flavor" -DLLVM_USE_CRT_RELEASE="$CRTLinkRelease" -DLLVM_USE_CRT_MINSIZEREL="$CRTLinkRelease" -DLLVM_APPEND_VC_REV=ON 
        #-DLLDB_TEST_COMPILER="$PWD\bin\$Flavor\clang.exe"
        if(Test-Path "build.ninja"){
            #&msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration="$Flavor" /p:Platform=x64 /t:ALL_BUILD
            &cmake --build . --config "$Flavor"
        }
    }elseif($Arch -eq "x86"){
        &cmake "..\$SourcesDir" -GNinja -DPYTHON_HOME="$PythonHome" -DLLDB_RELOCATABLE_PYTHON=1 -DCMAKE_CONFIGURATION_TYPES="$Flavor"  -DLLVM_ENABLE_ASSERTIONS=ON -DCMAKE_BUILD_TYPE="$Flavor" -DLLVM_USE_CRT_RELEASE="$CRTLinkRelease" -DLLVM_USE_CRT_MINSIZEREL="$CRTLinkRelease" -DLLVM_APPEND_VC_REV=ON 
        #-DLLDB_TEST_COMPILER="$PWD\bin\$Flavor\clang.exe"
        if(Test-Path "build.ninja"){
            #&msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration="$Flavor" /p:Platform=win32 /t:ALL_BUILD
            &cmake --build . --config "$Flavor"
        }
    }else{
        Write-Error "Build lldb current not support $Arch"
    }
}

if($LLDB){
    Write-Host "Start build llvm,include lldb"
    Start-MSbuildAddLLDB
}else{
    if($NMake){
        Start-NMakeBuilder
    }else{
        Start-MSBuild
    }
}

Function DoInstallCompilerRT{
    param(
        [String]$TargetDir,
        [String]$Configuration
    )
    $filelist=Get-ChildItem "$TargetDir"  -Recurse *.cmake | Foreach-Object {$_.FullName}
    foreach($file in $filelist){
        $content=Get-Content $file
        Clear-Content $file
        foreach($line in $content) {
            $lr=$line.Replace("`$(Configuration)", "$Configuration")
            Add-Content $file -Value $lr
        }
    }
}


if($lastexitcode -eq 0 -and $Install){
    if(Test-Path "$PWD/LLVM.sln"){
        #$(Configuration)
        DoInstallCompilerRT -TargetDir "./projects/compiler-rt/lib" -Configuration $Flavor
        &cpack -C "$Flavor"
    }
}
