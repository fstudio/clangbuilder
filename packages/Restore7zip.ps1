#
#
Set-StrictMode -Version latest

Function Expand-MsiPackage{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="MSI install package")]
        [ValidateNotNullorEmpty()]
        [String]$MsiPackage,
        [Parameter(Position=1,Mandatory=$True,HelpMessage="Output Directory")]
        [ValidateNotNullorEmpty()]
        [String]$Destination
    )
    if(Test-Path $MsiPackage){
        $retValue=99
        $process=Start-Process -FilePath "msiexec" -ArgumentList "/a `"$MsiPackage`" /qn TARGETDIR=`"$Destination`""  -PassThru -WorkingDirectory "$PSScriptRoot"
        Wait-Process -InputObject $process
        $retValue=$process.ExitCode
        if($retValue -eq 0){
            Write-Host "msiexec expend msi package success !"
            return $TRUE
        }
        Write-Error "Invoke msiexec expend package: $MsiPackage failed !"
    }else{
        Write-Error "Cannot found MSI Package: $MsiPackage"
    }
    return $FALSE
}

Import-Module -Name BitsTransfer
$IsWindows64=[System.Environment]::Is64BitOperatingSystem

$_7zipUrl="http://www.7-zip.org/a/7z1600.msi"

if($IsWindows64){
    $_7zipUrl="http://www.7-zip.org/a/7z1600-x64.msi"
}

Start-BitsTransfer -Source $_7zipUrl -Destination "$PSScriptRoot\7zip.msi" -Description "Downloading 7zip"
if(Test-Path "$PSScriptRoot\7zip.msi"){
    $result=Expand-MsiPackage -MsiPackage "$PSScriptRoot\7zip.msi" -Destination "$PSScriptRoot\7zip"
    if($result){
        Remove-Item "$PSScriptRoot\7zip.msi"
        Copy-Item -Path "$PSScriptRoot\7zip\Files\7-Zip\*" -Destination "$PSScriptRoot\7zip" -Force -Recurse
        Remove-Item -Force -Recurse "$PSScriptRoot\7zip\*.msi"
        Remove-Item -Force -Recurse "$PSScriptRoot\7zip\Files"
    }
}else{
    Write-Error "Download 7zip failed !"
}
