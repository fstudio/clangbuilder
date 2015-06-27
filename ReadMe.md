Clang Auto Builder
===
ClangOnWin Build Environment vNext, Long Term Evolution   

##Installation:
####Usually:
Download from Github, If your known use Git  

```
git clone https://github.com/fstudio/clangbuilder.git ClangSetupvNext 
```

Click the *Install.bat* in the ClangSetupvNext directory, this will run PowerShell startup  *InstallClangSetupvNext.ps1*      
It is recommended that whenever you have PowerShell scripts, and try not to delete the project file in the tools directory.

Similarly, you can start a PowerShell runs InstallClangSetupvNext.ps1, generally run PowerShell scripts on the Windows right-click menu option, you can right-click the menu "*run with PowerShell*"
Above procedure does not require administrator privileges.

If you are unable to run the script, please enter *Get-ExecutionPolicy* in the PowerShell,
If is:  
> Restricted 

Please run PowerShell with administrator rights, and Type:   

```
Set-ExecutionPolicy RemoteSigned
```

You have trouble, you can click on ***PowerShell.Setting.bat***, this batch script feature is to modify the PowerShell execution policy is written to the registry, the implementation process will automatically right, you need to select OK

####WebInstaller:

```
PS:\>iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/fstudio/clangbuilder/master/WebInstaller/install.ps1'))
```   

Or:  
```
C:\>powershell -NoProfile -ExecutionPolicy unrestricted -Command "iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/fstudio/clangbuilder/master/WebInstaller/install.ps1'))" 
```

**Your Should Input Your ClangSetup Install Loaction!!!!**


##ClangOnWin  

Build Clang,Base Visual Studio
>Visual Studio 2013 or Later,It's Best for VisualStudio 2013 Update 3<br>
>cl.exe 18.00.30723

Or Your can use Mingw-w64,your can cross compile LLVM on Linux ,Mingw-w64 Support it.

The Other,Your can use cmake to create MinGW Makefile,or NMake Makefile ,run it ,The C and C++ Compiler is Mingw-w64 tools ( i686-w64-mingw32-gcc ,x86_64-w64-mingw32-xxx)


##Automated build
Run    
```
PowerShell -File .\ClangBuilderPSvNext.ps1 
```
     
If not Param ,default VisualStudio version is 2013(VS120) Target:x86 Type:Release.    
```
PowerShell -File .\ClangBuilederPSNext.ps1 VS120 X86 Release MT MKI -C 
```

VisualStudio version:
>VS110 VS120 VS140

Platform:
>X86 X64 ARM(not support now)

Build Type:
>Release MinSizeRel RelWithDbgInfo Debug

C/C++ Runtime Library:
>MT(d) MD(d)

Make Install Package:
> MKI NOMKI

Using Clean Environment (PATH)
> -C


##User Interface(UI)
####Start Screen
Function:  
```
Show-LauncherWindow
```   
Base WPF.    
  
Start Screen:        
![Image](https://raw.githubusercontent.com/fstudio/clangbuilder/master/Images/StartWindow.jpg)

Function:
``` 
Get-ReadMeWindow
```    
Base WPF.           
ReadMeBox:      
![Image](https://raw.githubusercontent.com/fstudio/clangbuilder/master/Images/ReadMeWindow.jpg)

Upgrade Select:       
![Image](https://raw.githubusercontent.com/fstudio/clangbuilder/master/Images/UpdateSelect.jpg)

Other:      
OpenFileDialog(Vista Style),Popu Menu Select,PowerShell base Select Menu       
	
```
Show-OpenFileDialog ,New-Popup Select-MenuShow
```
####Voice

``` 
Out-ClangSetupTipsVoice 
```   

Copyright © 2015 ForceStudio. All Rights Reserved.
