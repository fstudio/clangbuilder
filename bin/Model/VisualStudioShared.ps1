<#############################################################################
#  VisualStudioShared.ps1
#  Note: Clangbuilder shared tools
#  Date:2016.01.01
#  Author:Force <forcemz@outlook.com>    
##############################################################################>

Function Get-RegistryValue($key, $value) { 
    (Get-ItemProperty $key $value).$value 
}

Function Get-RegistryValueEx{
    param(
        [ValidateNotNullorEmpty()]
        [String]$Path,
        [ValidateNotNullorEmpty()]
        [String]$Key
    )
    if(!(Test-Path $Path)){
        return 
    }
    (Get-ItemProperty $Path $Key).$Key
}

Function Push-PathBack{
    param(
        [ValidateNotNullorEmpty()]
        [String]$Path
    )
    if(Test-Path $Path){
        $env:PATH="$env:PATH;$PATH"
    }
}

Function Push-PathFront{
    param(
        [ValidateNotNullorEmpty()]
        [String]$Path
    )
    if(Test-Path $Path){
        $env:PATH="$PATH;$env:PATH"
    }
}

Function Push-Include{
    param(
        [ValidateNotNullorEmpty()]
        [String]$Include
    )
    if(Test-Path $Include){
        $env:INCLUDE="$Include;$env:INCLUDE"
    }
}

Function Push-LibraryDir{
    param(
        [ValidateNotNullorEmpty()]
        [String]$LibDIR
    )
    if(Test-Path $LibDIR){
        $env:LIB="$LibDIR;$env:LIB"
    }
}