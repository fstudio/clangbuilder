Clang Auto Builder
===
ClangOnWin Build Environment vNext, Long Term Evolution   

##Installation:
####Usually:
Download from Github, If your known use Git  

```
git clone https://github.com/fstudio/clangbuilder.git clangbuilder
```

Click the *Install.bat* in the clangbuilder directory, this will run PowerShell startup  *bin/Installer/Install.ps1*      
It is recommended that whenever you have PowerShell scripts, and try not to delete the project file in the tools directory.

Similarly, you can start a PowerShell runs Install.ps1, generally run PowerShell scripts on the Windows right-click menu option, you can right-click the menu "*run with PowerShell*"
Above procedure does not require administrator privileges.

If you are unable to run the script, please enter

```powershell
Get-ExecutionPolicy
```

Output:   

> Restricted

Please run PowerShell with administrator rights, and Enter:   

```powershell
Set-ExecutionPolicy RemoteSigned
```


####WebInstaller:

PowerShell, Enter:    
```powershell
&{$wc=New-Object System.Net.WebClient;$wc.Proxy=[System.Net.WebRequest]::DefaultWebProxy;$wc.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials;Invoke-Expression ($wc.DownloadString('https://raw.githubusercontent.com/fstudio/clangbuilder/master/bin/Installer/WebInstall.ps1'))}
```

Or:  

Cmd Enter:   
```cmd
@powershell -NoProfile -ExecutionPolicy unrestricted -Command "&{$wc=New-Object System.Net.WebClient;$wc.Proxy=[System.Net.WebRequest]::DefaultWebProxy;$wc.Proxy.Credentials=[System.Net.CredentialCache]::DefaultNetworkCredentials;Invoke-Expression ($wc.DownloadString('https://raw.githubusercontent.com/fstudio/clangbuilder/master/bin/Installer/WebInstall.ps1'))}"
```

**Your Should Input Your ClangSetup Install Loaction!!!!**


##ClangOnWin  

Build Clang,Base Visual Studio
>Visual Studio 2013 or Later,It's Best for VisualStudio 2013 Update 4

Or Your can use Mingw-w64,your can cross compile LLVM on Linux ,Mingw-w64 Support it.

The Other,Your can use cmake to create MinGW Makefile,or NMake Makefile ,run it ,The C and C++ Compiler is Mingw-w64 tools ( i686-w64-mingw32-gcc ,x86_64-w64-mingw32-g++)


##Automated build
Run    
```cmd
PowerShell -File .\bin\ClangbuilderManager.ps1 -VisualStudio 120 -Arch x64 -Flavor Release -Clear -Static
```



##User Interface
ClangbuilderUI        

![clangbuilderUI](https://raw.githubusercontent.com/fstudio/clangbuilder/master/doc/images/ClangbuilderUI.jpg)

Launcher       
![launcher](https://raw.githubusercontent.com/fstudio/clangbuilder/master/doc/images/launcher.jpg)


##Use Clean Environment
-Clear Flag will reset current process Environment Path Value.

##Other

Copyright © 2016 ForceStudio. All Rights Reserved.

