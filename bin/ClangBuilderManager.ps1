<#############################################################################
#  ClangBuilderManager.ps1
#  Note: Clang Auto Build TaskScheduler
#  Date:2016 01
#  Author:Force <forcemz@outlook.com>    
##############################################################################>
if($PSVersionTable.PSVersion.Major -lt 3)
{
    $PSVersionString=$PSVersionTable.PSVersion.Major
    Write-Host -ForegroundColor Red "Clangbuilder must run under PowerShell 3.0 or later host environment !"
    Write-Host -ForegroundColor Red "Your PowerShell Version:$PSVersionString"
    if($Host.Name -eq "ConsoleHost"){
        [System.Console]::ReadKey()
    }
    Exit
}
$WindowTitlePrefix="Clangbuilder PowerShell Utility"
Write-Host "Clang Auto Builder [PowerShell] Utility tools"
Write-Host "Copyright $([Char]0xA9) 2016. FroceStudio. All Rights Reserved."

$SelfFolder=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
$ClangbuilderRoot=Split-Path -Parent $SelfFolder
Import-Module "$SelfFolder/ClangBuilderUtility.ps1"

$EnabledNMake=$False
$EnableLLDB=$False
$UseClearEnv=$False
$UseStaticCRT=$False
$BuildReleasedRev=$False
$CreateInstallPkg=$False

$VisualStudioVersion=120
$VSTools="12"
$Target="x64"
$Configuration="Release"

if($args.Count -ge 1){
$args | foreach {
$va=$_
#
if($va -eq "-Nmake"){
$EnableNMake=$True
}
#
if($va -eq "-LLDB"){
$EnableLLDB=$True
}
#
if($va -eq "-Clear"){
$UseClearEnv=$True
}
#
if($va -eq "-Static"){
$UseStaticCRT=$True
}
#
if($va -eq "-Relased"){
$BuildReleasedRev=$True
}
#
if($va -eq "-Install"){
$CreateInstallPkg=$True
}
#
if($va -match "-V\d+"){
if($va -eq "-V110"){
$VisualStudioVersion=110
$VSTools="11"
}elseif($va -eq "-V120"){
$VisualStudioVersion=120
$VSTools="12"
}elseif($va -eq "-V140"){
$VisualStudioVersion=140
$VSTools="14"
}elseif($va -eq "-V141"){
$VisualStudioVersion=141
$VSTools="14"
}elseif($va -eq "-V150"){
$VisualStudioVersion=150
}ELSE{
Write-Host -ForegroundColor Red "Unknown VisualStudio Version: $va"
}
}
#
if($va -match "-T\w+"){
if($va -eq "-Tx86"){
$Target="x86"
}elseif($va -eq "-Tx64"){
$Target="x64"
}elseif($va -eq "-TARM"){
$Target="ARM"
}elseif($va -eq "-TARM64"){
$Target="ARM64"
}
}
#
if($va -match "-C\w+"){
if($va -eq "-CDebug"){
$Configuration="Debug";
}elseif($va -eq "-CRelease"){
$Configuration="Release"
}elseif($va -eq "-CMinSizeRel"){
$Configuration="MinSizeRel"
}elseif($va -eq "-CRelWithDebInfo"){
$Configuration="RelWithDebInfo"
}
}

}
#
}

if($UseClearEnv){
    Clear-Environment
}

Invoke-Expression -Command "$SelfFolder/Model/VisualStudioSub$VisualStudioVersion.ps1 $Target"
Invoke-Expression -Command "$SelfFolder/DiscoverToolChain.ps1"

if($EnableLLDB){
## Do fuck Restore LLDB Build Environment

if(!(Test-Path "$SelfFolder/Required/Python/python.exe")){
$EnableLLDB=$False
}
}

if($BuildReleasedRev){
$SourcesDir="release"
if($EnableLLDB){
Invoke-Expression -Command "$SelfFolder/RestoreClangReleased.ps1 --with-lldb"
}else{
Invoke-Expression -Command "$SelfFolder/RestoreClangReleased.ps1"
}
}else{
$SourcesDir="mainline"
if($EnableLLDB){
Invoke-Expression -Command "$SelfFolder/RestoreClangMainline.ps1 --with-lldb"
}else{
Invoke-Expression -Command "$SelfFolder/RestoreClangMainline.ps1"
}
}

if(!(Test-Path "$ClangbuilderRoot/out/workdir")){
mkdir "$ClangbuilderRoot/out/workdir"
}else{
Remove-Item -Force -Recurse "$ClangbuilderRoot/out/workdir/*"
}

Set-Location "$ClangbuilderRoot/out/workdir"

if($UseStaticCRT){
$CRTLinkRelease="MT"
$CRTLinkDebug="MTd"
}else{
$CRTLinkRelease="MD"
$CRTLinkDebug="MDd"
}


if($NmakeEnable){
Invoke-Expression -Command  "cmake ..\$SourcesDir -G`"NMake Makefiles`" -DCMAKE_CONFIGURATION_TYPES=$Configuration -DCMAKE_BUILD_TYPE=$Configuration -DLLVM_USE_CRT_DEBUG=$CRTLinkDebug -DLLVM_USE_CRT_RELEASE=$CRTLinkRelease -DLLVM_USE_CRT_MINSIZEREL=$CRTLinkRelease -DLLVM_USE_CRT_RELWITHDBGINFO=$CRTLinkRelease    -DLLVM_APPEND_VC_REV:BOOL=ON "  

if(Test-Path "Makefile"){
Invoke-Expression -Command "nmake"
}

}else{

if($Target -eq "x64"){
Invoke-Expression -Command "cmake ..\$SourcesDir -G`"Visual Studio $VSTools Win64`" -DCMAKE_CONFIGURATION_TYPES=$Configuration -DCMAKE_BUILD_TYPE=$Configuration -DLLVM_USE_CRT_DEBUG=$CRTLinkDebug -DLLVM_USE_CRT_RELEASE=$CRTLinkRelease -DLLVM_USE_CRT_MINSIZEREL=$CRTLinkRelease -DLLVM_USE_CRT_RELWITHDBGINFO=$CRTLinkRelease    -DLLVM_APPEND_VC_REV:BOOL=ON " 

if(Test-Path "LLVM.sln"){
Invoke-Expression -Command "msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration=$Configuration /p:Platform=x64 /t:ALL_BUILD"
}

}elseif($Target -eq "ARM"){

Invoke-Expression -Command "cmake ..\$SourcesDir -G`"Visual Studio $VSTools ARM`" -DCMAKE_CONFIGURATION_TYPES=$Configuration -DCMAKE_BUILD_TYPE=$Configuration -DLLVM_USE_CRT_DEBUG=$CRTLinkDebug -DLLVM_USE_CRT_RELEASE=$CRTLinkRelease -DLLVM_USE_CRT_MINSIZEREL=$CRTLinkRelease -DLLVM_USE_CRT_RELWITHDBGINFO=$CRTLinkRelease    -DLLVM_APPEND_VC_REV:BOOL=ON "  

if(Test-Path "LLVM.sln"){
Invoke-Expression -Command "msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration=$Configuration /p:Platform=ARM /t:ALL_BUILD"
}

}elseif($Target -eq "ARM64" -and $VisualStudioVersion -ge 141){

Invoke-Expression -Command "cmake ..\$SourcesDir -G`"Visual Studio $VSTools ARM64`" -DCMAKE_CONFIGURATION_TYPES=$Configuration -DCMAKE_BUILD_TYPE=$Configuration -DLLVM_USE_CRT_DEBUG=$CRTLinkDebug -DLLVM_USE_CRT_RELEASE=$CRTLinkRelease -DLLVM_USE_CRT_MINSIZEREL=$CRTLinkRelease -DLLVM_USE_CRT_RELWITHDBGINFO=$CRTLinkRelease    -DLLVM_APPEND_VC_REV:BOOL=ON "  

if(Test-Path "LLVM.sln"){
Invoke-Expression -Command "msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration=$Configuration /p:Platform=ARM64 /t:ALL_BUILD"
}
}else{

Invoke-Expression -Command "cmake ..\$SourcesDir -G`"Visual Studio $VSTools`" -DCMAKE_CONFIGURATION_TYPES=$Configuration -DCMAKE_BUILD_TYPE=$Configuration -DLLVM_USE_CRT_DEBUG=$CRTLinkDebug -DLLVM_USE_CRT_RELEASE=$CRTLinkRelease -DLLVM_USE_CRT_MINSIZEREL=$CRTLinkRelease -DLLVM_USE_CRT_RELWITHDBGINFO=$CRTLinkRelease    -DLLVM_APPEND_VC_REV:BOOL=ON "  

if(Test-Path "LLVM.sln"){
Invoke-Expression -Command "msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration=$Configuration /p:Platform=win32 /t:ALL_BUILD"
}
#
}
#
}

if($? -eq $True -and $CreateInstallPkg){
if(Test-Path "$PWD/LLVM.sln"){
Invoke-Expression -Command "cpack -C $Configuration"
}
}




