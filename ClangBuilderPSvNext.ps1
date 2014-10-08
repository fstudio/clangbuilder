<#############################################################################
#  ClangBuilderPS.ps1
#  Note: Clang Auto Build TaskScheduler
#  Data:2014 08
#  Author:Force <forcemz@outlook.com>    
##############################################################################>
IF($PSVersionTable.PSVersion.Major -lt 3)
{
Write-Host -ForegroundColor Red "ClangSetup Builder PowerShell vNext Must Run on Windows PowerShell 3 or Later,`nYour PowerShell version Is : 
${Host}"
[System.Console]::ReadKey()
Exit
}
IF($args.Count -le 4)
{

}
$WindowTitlePrefix=" ClangSetup PowerShell Builder"
Write-Host "ClangSetup Auto Builder [PowerShell] tools"
Write-Host "Copyright $([Char]0xA9) 2014 FroceStudio All Rights Reserved."
<#
LLVM tools and Library subversion URL:
http://llvm.org/svn/llvm-project/llvm/trunk
http://llvm.org/svn/llvm-project/cfe/trunk
http://llvm.org/svn/llvm-project/clang-tools-extra/trunk
http://llvm.org/svn/llvm-project/compiler-rt/trunk
http://llvm.org/svn/llvm-project/libcxx/trunk
http://llvm.org/svn/llvm-project/libcxxabi/trunk
http://llvm.org/svn/llvm-project/lld/trunk
http://llvm.org/svn/llvm-project/lldb/trunk
http://llvm.org/svn/llvm-project/polly/trunk

#>
#get-alias
#Set-Location 
#IEX -Command “${PrefixDir}\ClangSetupPS.ps1”
#$PrefixDir=[System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
$BDVSV="12"
$BDTAG="x86"
$BDTYPE="Release"
$BDCRT="MT"

IF($args.Count -ge 1)
{
}



$PrefixDir=Split-Path -Parent $MyInvocation.MyCommand.Definition
Invoke-Expression -Command "${PrefixDir}\bin\CSEvNInternal.ps1"
Invoke-Expression -Command "${PrefixDir}\bin\VisualStudioHub.ps1  VS${BDVSV}0 ${BDTAG}"

#Write-Host $PrefixDir
Set-Location $PrefixDir
$BuildDirOK=Test-Path "${PrefixDir}\Build"
IF($BuildDirOK -ne $true)
{
 mkdir  "${PrefixDir}\Build"
}ELSE
{
  Remove-Item "${PrefixDir}\Build\*" -Force  -Recurse
}
<################################################################################################
#  Subversion Checkout source code.
#  Start-Process notepad -Wait -WindowStyle Maximized -verb runAs
################################################################################################>
Set-Location "${PrefixDir}\Build"
#Start-Process -FilePath svn.exe -ArgumentList "co http://llvm.org/svn/llvm-project/llvm/trunk llvm" -NoNewWindow -Wait
Invoke-Expression -Command "svn co  http://llvm.org/svn/llvm-project/llvm/trunk llvm"
#Remove-Item "${PrefixDir}\Build\llvm\.svn\" -Force -Recurse
Set-Location "${PrefixDir}\Build\llvm\tools"
#Start-Process -FilePath svn.exe -ArgumentList "co http://llvm.org/svn/llvm-project/cfe/trunk clang" -NoNewWindow -Wait
Invoke-Expression -Command "svn co  http://llvm.org/svn/llvm-project/cfe/trunk clang"
#Remove-Item "${PrefixDir}\Build\llvm\tools\clang\.svn\" -Force -Recurse
Set-Location "${PrefixDir}\Build\llvm\tools\clang\tools"
#Start-Process -FilePath svn.exe -ArgumentList "co http://llvm.org/svn/llvm-project/clang-tools-extra/trunk extra" -NoNewWindow -Wait
Invoke-Expression -Command "svn co  http://llvm.org/svn/llvm-project/clang-tools-extra/trunk extra"
#Remove-Item "${PrefixDir}\Build\llvm\tools\clang\tools\extra\.svn\" -Force -Recurse
Set-Location "${PrefixDir}\Build\llvm\tools"
#Start-Process -FilePath svn.exe -ArgumentList "co http://llvm.org/svn/llvm-project/lld/trunk lld" -NoNewWindow -Wait
Invoke-Expression -Command "svn co  http://llvm.org/svn/llvm-project/lld/trunk lld"
#Remove-Item "${PrefixDir}\Build\llvm\tools\lld\.svn\" -Force -Recurse
Set-Location "${PrefixDir}\Build\llvm\projects"
Invoke-Expression -Command "svn co http://llvm.org/svn/llvm-project/compiler-rt/trunk compiler-rt"

###
# Checkout End.
#####
#Write-Output
$OutDirExist=Test-Path "${PrefoxDir}\Build\Out"
IF($OutDirExist -eq $true)
{
Remove-Item "${PrefixDir}\Build\Out\*" -Force -Recurse
}else{
Mkdir "${PrefixDir}\Build\Out"
}

####Default
Set-Location "${PrefixDir}\Build\Out"
#Default Options

IF([System.String]::Compare($BDTAG, "X64") -eq $True)
{
   Invoke-Expression -Command "cmake ..\llvm -G `"Visual Studio ${BDVSV} Win64`" -DLLVM_USE_CRT_MINSIZEREL:STRING=${BDCRT} -DLLVM_USE_CRT_RELEASE:STRING=${BDCRT} -DCMAKE_BUILD_TYPE:STRING=${BDTYPE} -DLLVM_APPEND_VC_REV:BOOL=ON "
   Invoke-Expression -Command "msbuild LLVM.sln /t:Rebuild /p:Configuration=${BDTYPE};/p:Platform=x64"
}ELSEIF([System.String]::Compare($BDTAG, "ARM") -eq $true){
  Invoke-Expression -Command "cmake ..\llvm -G `"Visual Studio ${BDVSV} ARM`" -DLLVM_USE_CRT_MINSIZEREL:STRING=${BDCRT} -DLLVM_USE_CRT_RELEASE:STRING=${BDCRT} -DCMAKE_BUILD_TYPE:STRING=${BDTYPE} -DLLVM_APPEND_VC_REV:BOOL=ON "
  Invoke-Expression -Command "msbuild LLVM.sln /t:Rebuild /p:Configuration=${BDTYPE};/p:Platform=ARM"
}ELSE{
Invoke-Expression -Command "cmake ..\llvm -G `"Visual Studio ${BDVSV}`" -DLLVM_USE_CRT_MINSIZEREL:STRING=${BDCRT} -DLLVM_USE_CRT_RELEASE:STRING=${BDCRT} -DCMAKE_BUILD_TYPE:STRING=${BDTYPE} -DLLVM_APPEND_VC_REV:BOOL=ON "
Invoke-Expression -Command "msbuild LLVM.sln /t:Rebuild /p:Configuration=${BDTYPE};/p:Platform=x86"
}
#Invoke-Expression -Command "cmake ..\llvm -G `"Visual Studio 12`" -DLLVM_TARGETS_TO_BUILD=`"X86;ARM`""

Write-Host -ForegroundColor Cyan "Automatic build LLVM is completed"
Invoke-Expression -Command "cpack "
Write-Host -ForegroundColor Cyan "Installation package finished."

Write-Host "Options End." -ForegroundColor DarkYellow
Write-Host
###New Line
if($args.Count -ge 2)
{
###Invoke
}else
{
  Invoke-Expression -Command 'PowerShell -NoLogo'
}