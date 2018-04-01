
Function Get-PythonInstall{
    $IsWin64=[System.Environment]::Is64BitOperatingSystem
    if($IsWin64 -and ($Arch -eq "x86")){
        $PythonRegKey="HKCU:\SOFTWARE\Python\PythonCore\3.5-32\InstallPath"    
    }else{
        $PythonRegKey="HKCU:\SOFTWARE\Python\PythonCore\3.5\InstallPath"
    }
    if(Test-Path $PythonRegKey){
        return (Get-ItemProperty $PythonRegKey).'(default)'
    }
    return $null
}

    $PythonHome=Get-PythonInstall
    if($null -eq $PythonHome){
        Write-Error "Cannot found Python install !"
        Exit 
    }
    
    Write-Host $PythonHome
    