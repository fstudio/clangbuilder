<#############################################################################
#  PackageManager.ps1
#  Note: Clang Auto Build Package Manager  
#  Data:2015.01.01
#  Author:Force <forcemz@outlook.com>    
##############################################################################>



Function Global:Check-PackageList{
 retrun $TRUE
}


Function Global:Check-PackageWithLLDB
{
 return $FALSE
}


Function Global:Create-InstallPackage
{
 cpack --help |OUT-NULL
 IF ( $? -eq $FALSE)
 {
   return $FALSE
 }
 $ret=IEX -Command "cpack"
 IF{$ret -eq $FALSE}
 {
  return $FALSE;
 }
 return $TRUE
}