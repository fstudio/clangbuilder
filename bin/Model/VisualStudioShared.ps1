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

Function Invoke-BatchFile{
    param(
        [Parameter(Mandatory=$true)]
        [string] $Path,
        [string] $ArgumentList
    )
    Set-StrictMode -Version Latest
    $tempFile=[IO.Path]::GetTempFileName()
    cmd /c " `"$Path`" $argumentList && set > `"$tempFile`" "
    ## Go through the environment variables in the temp file.
    ## For each of them, set the variable in our local environment.
    Get-Content $tempFile | Foreach-Object {
        if($_ -match "^(.*?)=(.*)$")
        {
            Set-Content "env:\$($matches[1])" $matches[2]
        }
    }
    Remove-Item $tempFile
}