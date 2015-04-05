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

$WindowTitlePrefix=" ClangSetup PowerShell Builder"
Write-Host "ClangSetup Auto Builder [PowerShell] tools"
Write-Host "Copyright $([Char]0xA9) 2015 FroceStudio All Rights Reserved."
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
$BDTAG="X86"
$BDTYPE="Release"
$BDCRT="MT"
[System.Boolean] $IsMakeInstall=$True

$PrefixDir=Split-Path -Parent $MyInvocation.MyCommand.Definition


<#
#################################################################################################
#  Subversion Checkout source code.
#  Start-Process notepad -Wait -WindowStyle Maximized -verb runAs
#################################################################################################
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

##>

Function Global:Get-LLVMSource([String]$sourceroot)
{
  IF(!(Test-Path "$sourceroot"))
  {
   return $False
  }
  Set-Location $sourceroot
  ############
   IF(!(Test-Path "$sourceroot\llvm\.svn"))
   {
    IF(Test-Path "$sourceroot\llvm")
    {
      Remove-Item -Force -Recurse  "$sourceroot\llvm"
    }
    Invoke-Expression -Command "svn co  http://llvm.org/svn/llvm-project/llvm/trunk llvm"
   }ELSE{
    Invoke-Expression -Command "svn cleanup llvm"
    Invoke-Expression -Command "svn up llvm"
   }
   ##############
   IF(!(Test-Path "$sourceroot\llvm\tools\clang\.svn"))
   {
   Set-Location "${sourceroot}\llvm\tools"
    IF(Test-Path "$sourceroot\llvm\tools\clang")
    {
      Remove-Item -Force -Recurse  "$sourceroot\llvm\tools\clang"
    }
    Invoke-Expression -Command "svn co  http://llvm.org/svn/llvm-project/cfe/trunk clang"
   }ELSE{
      Set-Location "${sourceroot}\llvm\tools\clang"
    Invoke-Expression -Command "svn cleanup ."
    Invoke-Expression -Command "svn up ."
   }
   ###########
   IF(!(Test-Path "$sourceroot\llvm\tools\lld\.svn"))
   {
    IF(Test-Path "$sourceroot\llvm\tools\lld")
    {
      Remove-Item -Force -Recurse  "$sourceroot\llvm\tools\lld"
    }
    Invoke-Expression -Command "svn co  http://llvm.org/svn/llvm-project/lld/trunk lld"
   }ELSE{
      Set-Location "${sourceroot}\llvm\tools\lld"
    Invoke-Expression -Command "svn cleanup ."
    Invoke-Expression -Command "svn up ."
   }

 ####################
   IF(!(Test-Path "$sourceroot\llvm\tools\clang\tools\extra\.svn"))
   {
    Set-Location "${sourceroot}\llvm\tools\clang\tools"
    IF(Test-Path "$sourceroot\llvm\tools\clang\tools\extra")
    {
      Remove-Item -Force -Recurse  "$sourceroot\llvm\tools\clang\tools\extra"
    }
    Invoke-Expression -Command "svn co  http://llvm.org/svn/llvm-project/clang-tools-extra/trunk extra"
   }ELSE{
      Set-Location "${sourceroot}\llvm\tools\clang\tools\extra"
    Invoke-Expression -Command "svn cleanup ."
    Invoke-Expression -Command "svn up ."
   }
   ##################################
   IF(!(Test-Path "$sourceroot\llvm\projects\compiler-rt\.svn"))
   {
    Set-Location "${sourceroot}\llvm\projects"
    IF(Test-Path "$sourceroot\llvm\projects\compiler-rt")
    {
      Remove-Item -Force -Recurse  "$sourceroot\llvm\projects\compiler-rt"
    }
    Invoke-Expression -Command "svn co  http://llvm.org/svn/llvm-project/compiler-rt/trunk compiler-rt"
   }ELSE{
     Set-Location "${sourceroot}\llvm\projects\compiler-rt"
    Invoke-Expression -Command "svn cleanup ." 
    Invoke-Expression -Command "svn up ."
   }
   return $True
}


Function Global:Delete-LLVMSource([String]$sourcefolder)
{
IF((Test-Path $sourcefolder))
{
 if((New-PopuShow -message "Shell Will delete $sourcefolder" -title "ClangBuilder Warning" -time 5 -Buttons OKCancel -Icon Exclamation) -eq 1)
 {
 Remove-Item -Force -Recurse $sourcefolder
 }
 ELSE{
 Write-Host -ForegroundColor Yellow  "The user chose to cancel the delete directory"
 }
}
}




IF($args.Count -ge 1)
{
IF([System.String]::Compare($args[0],"VS110") -eq 0)
{
  $BDVSV="11"
}
IF([System.String]::Compare($args[0],"VS140") -eq 0)
{
  $BDVSV="14"
}
IF([System.String]::Compare($args[0],"VS150") -eq 0)
{
  $BDVSV="15"
}
}

IF($args.Count -ge 2)
{
IF([System.String]::Compare($args[1],"X64") -eq 0)
{
  $BDTAG="X64"
}
IF([System.String]::Compare($args[1],"ARM") -eq 0)
{
  $BDTAG="ARM"
}
IF([System.String]::Compare($args[1],"AArch64") -eq 0)
{
  $BDTAG="AArch64"
}
}

IF($args.Count -ge 3)
{
 IF([System.String]::Compare($args[2],"MinSizeRel") -eq 0)
 {
  $BDTYPE="MinSizeRel"
 }
  IF([System.String]::Compare($args[2],"RelWithDbgInfo") -eq 0)
 {
  $BDTYPE="RelWithDbgInfo"
 }
  IF([System.String]::Compare($args[2],"Debug") -eq 0)
 {
  $BDTYPE="Debug"
 }
}
IF($args.Count -ge 4)
{
 IF([System.String]::Compare($args[3],"MD") -eq 0)
 {
  $BDCRT="MD"
 }
}
IF($args.Count -ge 5)
{
 IF([System.String]::Compare($args[4],"NOMKI") -eq 0)
 {
  $IsMakeInstall=$false
 }
}
IF($args.Count -ge 6 -and [System.String]::Compare($args[5],"-E") -eq 0)
{
 IEX -Command "${PrefixDir}\bin\ClearPathValue.ps1"
}


Invoke-Expression -Command "${PrefixDir}\bin\CSEvNInternal.ps1"
Invoke-Expression -Command "${PrefixDir}\bin\VisualStudioHub.ps1  VS${BDVSV}0 ${BDTAG}"

#Write-Host $PrefixDir
Set-Location $PrefixDir
$BuildDirOK=Test-Path "${PrefixDir}\Build"
IF($BuildDirOK -ne $true)
{
 mkdir  "${PrefixDir}\Build"
}
Get-LLVMSource  "${PrefixDir}\Build"
###
# Checkout End.
#####
#Write-Output
$OutDirExist=Test-Path "${PrefixDir}\Build\Out"
IF($OutDirExist -eq $true)
{
Remove-Item "${PrefixDir}\Build\Out\*" -Force -Recurse
}else{
Mkdir "${PrefixDir}\Build\Out"
}

####Default
Set-Location "${PrefixDir}\Build\Out"
#Default Options
IF($args.Count -ge 7 -and [System.String]::Compare($args[6],"-NMake") -eq 0)
{
  Invoke-Expression -Command "cmake ..\llvm -G`"NMake Makefiles`" -DCMAKE_BUILD_TYPE=MinSizeRel  -DLLVM_USE_CRT_MINSIZEREL:STRING=${BDCRT} -DLLVM_USE_CRT_RELEASE:STRING=${BDCRT} -DCMAKE_BUILD_TYPE:STRING=${BDTYPE}  -DCMAKE_CONFIGURATION_TYPES:STRING=${BDTYPE} -DLLVM_APPEND_VC_REV:BOOL=ON "
  Invoke-Expression -Command "nmake"
}ELSE{
IF([System.String]::Compare($BDTAG, "X64") -eq 0)
{
  Invoke-Expression -Command "cmake ..\llvm -G `"Visual Studio ${BDVSV} Win64`" -DLLVM_USE_CRT_MINSIZEREL:STRING=${BDCRT} -DLLVM_USE_CRT_RELEASE:STRING=${BDCRT} -DCMAKE_BUILD_TYPE:STRING=${BDTYPE} -DCMAKE_CONFIGURATION_TYPES:STRING=${BDTYPE} -DLLVM_APPEND_VC_REV:BOOL=ON "
  Invoke-Expression -Command "msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration=${BDTYPE} /p:Platform=x64"
}ELSEIF([System.String]::Compare($BDTAG, "ARM") -eq 0){
  Invoke-Expression -Command "cmake ..\llvm -G `"Visual Studio ${BDVSV} ARM`" -DLLVM_USE_CRT_MINSIZEREL:STRING=${BDCRT} -DLLVM_USE_CRT_RELEASE:STRING=${BDCRT} -DCMAKE_BUILD_TYPE:STRING=${BDTYPE}  -DCMAKE_CONFIGURATION_TYPES:STRING=${BDTYPE} -DLLVM_APPEND_VC_REV:BOOL=ON "
  Invoke-Expression -Command "msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration=${BDTYPE} /p:Platform=ARM"
}ELSE{
Invoke-Expression -Command "cmake ..\llvm -G `"Visual Studio ${BDVSV}`" -DLLVM_USE_CRT_MINSIZEREL:STRING=${BDCRT} -DLLVM_USE_CRT_RELEASE:STRING=${BDCRT} -DCMAKE_BUILD_TYPE:STRING=${BDTYPE}  -DCMAKE_CONFIGURATION_TYPES:STRING=${BDTYPE} -DLLVM_APPEND_VC_REV:BOOL=ON "
Invoke-Expression -Command "msbuild /nologo LLVM.sln /t:Rebuild /p:Configuration=${BDTYPE} /p:Platform=win32"
}
}

#Invoke-Expression -Command "cmake ..\llvm -G `"Visual Studio 12`" -DLLVM_TARGETS_TO_BUILD=`"X86;ARM`""

Write-Host -ForegroundColor Cyan "Automatic build LLVM is completed"
IF($IsMakeInstall -and $? -eq $True)
{
Invoke-Expression -Command "cpack "
IF($? -eq $True){
Write-Host -ForegroundColor Cyan "Installation package finished."}ELSE{
  Write-Host -ForegroundColor Red  "Make Install Packeage Error! Your Should Check Error Info."
}
}ELSE
{
Write-Host -ForegroundColor Green "Not Make Install Packeage."
}


Write-Host "Options End.`n" -ForegroundColor DarkYellow
###New Line
if($args.Count -ge 2)
{
###Invoke
}else
{
  Invoke-Expression -Command 'PowerShell -NoLogo'
}
