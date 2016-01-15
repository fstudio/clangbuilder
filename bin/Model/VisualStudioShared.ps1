<#############################################################################
#  VisualStudioShared.ps1
#  Note: Clangbuilder shared tools
#  Date:2016.01.01
#  Author:Force <forcemz@outlook.com>    
##############################################################################>

Function Get-RegistryValue($key, $value) { 
    (Get-ItemProperty $key $value).$value 
}