## Powershell Package Initialize

Function Find-ExecutablePath {
    param(
        [String]$Path
    )
    if(!(Test-Path $Path)){
        return $null
    }
    $files= Get-ChildItem -Path "$Path\*.exe"
    if($files.Count -ge 1){
        return $Path
    }
    if ((Test-Path "$Path\bin")) {
        return "$Path\bin"
    }
    if ((Test-Path "$Path\cmd")) {
        return "$Path\cmd"
    }
    return $null
}


Function Test-AddPath {
    param(
        [String]$Path
    )
    if (Test-Path $Path) {
        $env:Path = "$Path;${env:Path}"
    }
}

Function Test-ExecuteFile {
    param(
        [Parameter(Position = 0, Mandatory = $True, HelpMessage = "Enter Execute Name")]
        [ValidateNotNullorEmpty()]
        [String]$ExeName
    )
    $myErr = @()
    Get-command -CommandType Application $ExeName -ErrorAction SilentlyContinue -ErrorVariable +myErr
    if ($myErr.count -eq 0) {
        return $True
    }
    return $False
}

Function Get-RegistryValueEx {
    param(
        [ValidateNotNullorEmpty()]
        [String]$Path,
        [ValidateNotNullorEmpty()]
        [String]$Key
    )
    if (!(Test-Path $Path)) {
        return 
    }
    (Get-ItemProperty $Path $Key).$Key
}


Function InitializePackageEnv{
    param(
        [String]$ClangbuilderRoot
    )
    $obj= Get-Content -Path "$ClangbuilderRoot\pkgs\packages.lock.json" |ConvertFrom-Json
    Get-Member -InputObject $obj -MemberType NoteProperty|ForEach-Object{
        $xpath = Find-ExecutablePath -Path "$ClangbuilderRoot\pkgs\$($_.Name)"
        if ($null -ne $xpath) {
            Test-AddPath -Path $xpath
        }
    }
    if (!(Test-ExecuteFile "git")) {
        $gitkey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
        $gitkey2 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Git_is1"
        if (Test-Path $gitkey) {
            $gitinstall = Get-RegistryValueEx $gitkey "InstallLocation"
            Test-AddPath "${gitinstall}\bin"
        }
        elseif (Test-Path $gitkey2) {
            $gitinstall = Get-RegistryValueEx $gitkey2 "InstallLocation"
            Test-AddPath "${gitinstall}\bin"
        }
    }
}
