ClangSetup vNext
===
ClangOnWin Build Environment vNext, Long Term Evolution <br>

##Installation:
Click the *Install.bat* in the ClangSetupvNext directory, this will run PowerShell startup

**InstallClangSetupvNext.ps1**, It is recommended that whenever you have PowerShell scripts, and try not to delete the project file in the tools directory.

Similarly, you can start a PowerShell runs InstallClangSetupvNext.ps1, generally run PowerShell scripts on the Windows right-click menu option, you can right-click the menu "*run with PowerShell*"
Above procedure does not require administrator privileges.

If you are unable to run the script, please enter **Get-ExecutionPolicy** in the PowerShell,
If is: 
> Restricted 

Please run PowerShell with administrator rights, and Type: 

    Set-ExecutionPolicy RemoteSigned

You have trouble, you can click on ***PowerShell.Setting.bat***, this batch script feature is to modify the PowerShell execution policy is written to the registry, the implementation process will automatically right, you need to select OK

##ClangOnWin 

Build Clang,Base Visual Studio
>Visual Studio 2013 or Later,It's Best for VisualStudio 2013 Update 3<br>
>cl.exe 18.00.30723

Or Your can use Mingw-w64,your can cross compile LLVM on Linux ,Mingw-w64 Support it.

The Other,Your can use cmake to create MinGW Makefile,or NMake Makefile ,run it ,The C and C++ Compiler is Mingw-w64 tools ( i686-w64-mingw32-gcc ,x86_64-w64-mingw32-xxx)





##AutoBuilder
Run<br>
```PowerShell -File .\ClangBuilderPSvNext.ps1 ```<br>
If not Param ,default VisualStudio version is x86.<br>

```PowerShell -File .\ClangBuilederPSNext.ps1 VS120 X86 Release MT MKI -C ```

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
Function:```Show-LauncherWindow``` Base WPF.<br>
Start Screen:
![Image](Images/StartWindow.jpg)

Function:``` Get-ReadMeWindow``` Base WPF.<br>
ReadMeBox:
![Image](Images/ReadMeWindow.jpg)

Other:<br>
OpenFileDialog(Vista Style),Popu Menu Select,PowerShell base Select Menu 
```Show-OpenFileDialog ,New-Popup Select-MenuShow```
####Voice
``` Out-ClangSetupTipsVoice```

Copyright &copy; 2014 ForceStudio.All Rights Reserved.