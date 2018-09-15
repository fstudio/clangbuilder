param(
 [String]$Name
)

$Global:Subffix = ""
if ($PSEdition -eq "Desktop" -or $IsWindows) {
    $Global:Subffix = ".exe"
}

Function Findcommand {
    param(
        [String]$Name
    )
    $Exe=$Name+$Global:Subffix
    Write-Host "Debug: $Exe"
 
    $command = Get-Command -CommandType Application -ErrorAction SilentlyContinue $Exe
    if ($null -eq $command) {
        Write-Host "cannot found $Exe"
        return $null
    }
    Write-Host "found $($command.Source)"
    return $command.Source.ToString()
}

$cmd=Findcommand -Name $Name
Write-Host "Get $cmd"