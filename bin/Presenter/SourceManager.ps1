<#############################################################################
#  SourceManager.ps1
#  Note: Clang Auto Build Source Manager  API
#  Data:2015.01.01
#  Author:Force <forcemz@outlook.com>    
##############################################################################>


Function Global:Run-SVNCheckout{
Write-Host -ForegroundColor Green "Run Subversion checkout LLVM Sources"
svn --version |Out-NULL
IF( $? -eq $false)
{
  Write-Host  -ForegroundColor Red "Not Found Subversion Client:svn in your PATH,Please Reset it."
  #[System.Console]::ReadKey()
  return $false
}

return $true
}


Function Global:Run-GitClone{
}

Run-SVNCheckout