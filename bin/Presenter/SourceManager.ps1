<#############################################################################
#  SourceManager.ps1
#  Note: Clang Auto Build Source Manager Throw API
#  Data:2015.01.01
#  Author:Force <forcemz@outlook.com>    
##############################################################################>


Function Global::Run-SVNCheckout{
Write-Host -BackgroundColor Green "Run Subversion checkout LLVM Sources"
svn --version |Out-NULL
IF( $? -eq $false)
{
  Write-Host -BackgroundColor Red "Not Found Subversion Client:svn in your PATH,Please Reset it."
  [System.Console]::ReadKey()
  return $false
}

return $true
}


Function Global::Run-GitClone{
}