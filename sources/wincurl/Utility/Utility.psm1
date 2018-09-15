# Powershell module

Function Exec {
    param(
        [string]$FilePath,
        [string]$Argv,
        [string]$WD
    )
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $FilePath
    Write-Host "$FilePath $Argv [$WD] "
    if ([String]::IsNullOrEmpty($WD)) {
        $ProcessInfo.WorkingDirectory = $PWD
    }
    else {
        $ProcessInfo.WorkingDirectory = $WD
    }
    $ProcessInfo.Arguments = $Argv
    $ProcessInfo.UseShellExecute = $false ## use createprocess not shellexecute
    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $ProcessInfo
    if ($Process.Start() -eq $false) {
        return -1
    }
    $Process.WaitForExit()
    return $Process.ExitCode
}

Function Findcommand {
    param(
        [String]$Name
    )
    $command = Get-Command -CommandType Application $Name -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        return $null
    }
    return $command[0].Source
}

Function MkdirAll {
    param(
        [String]$Dir
    )
    try {
        New-Item -ItemType Directory -Force $Dir
    }
    catch {
        Write-Host -ForegroundColor Red "mkdir $Dir error: $_"
        return $false
    }
    return $true
}

Function WinGet {
    param(
        [String]$URL,
        [String]$O
    )
    # 
    Write-Host "Download: $O"
    $UserAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::Chrome
    try {
        Invoke-WebRequest -Uri $URL -OutFile $O -UseBasicParsing -UserAgent $UserAgent

    }
    catch {
        Write-Host -ForegroundColor Red "download $O failed: $_"
        return $false
    }
    return $true
}


