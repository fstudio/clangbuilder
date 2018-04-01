Function Global:ProcesssStart {
    param(
        [string]$FilePath,
        [string]$Arguments
    )
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo 
    $ProcessInfo.FileName = $FilePath
    $ProcessInfo.UseShellExecute = $false 
    $ProcessInfo.Arguments = $Arguments
    $Process = New-Object System.Diagnostics.Process 
    $Process.StartInfo = $ProcessInfo 
    $Process.Start() | Out-Null 
    $Process.WaitForExit()
    return $process.ExitCode
}
