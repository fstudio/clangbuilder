ClangSetup vNext
===
ClangOnWin Build Environment vNext, Long Term Evolution <br>

Installation:
---
Click the *Install.bat* in the ClangSetupvNext directory, this will run PowerShell startup

**InstallClangSetupvNext.ps1**, It is recommended that whenever you have PowerShell scripts, and try not to delete the project file in the tools directory.

Similarly, you can start a PowerShell runs InstallClangSetupvNext.ps1, generally run PowerShell scripts on the Windows right-click menu option, you can right-click the menu "*run with PowerShell*"
Above procedure does not require administrator privileges.

If you are unable to run the script, please enter **Get-ExecutionPolicy** in the PowerShell,
If Yes: 
> Restricted 

Please run PowerShell with administrator rights, and Type: 

    Set-ExecutionPolicy RemoteSigned

You have trouble, you can click on ***PowerShell.Setting.bat***, this batch script feature is to modify the PowerShell execution policy is written to the registry, the implementation process will automatically right, you need to select OK