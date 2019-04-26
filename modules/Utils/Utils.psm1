### Utils.psm1

Function Parallel() {
    $MemSize = (Get-CimInstance -Class Win32_ComputerSystem).TotalPhysicalMemory
    $ProcessorCount = $env:NUMBER_OF_PROCESSORS
    $MemParallelRaw = $MemSize / 1610612736 #1.5GB
    #[int]$MemParallel = [Math]::Floor($MemParallelRaw)
    [int]$MemParallel = [Math]::Ceiling($MemParallelRaw)
    return [Math]::Min($ProcessorCount, $MemParallel)
}

# On Windows, Start-Process -Wait will wait job process, obObject.WaitOne(_waithandle);
# Don't use it
Function ProcessExec {
    param(
        [string]$FilePath,
        [string]$Arguments,
        [string]$WorkingDirectory
    )
    $ProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessInfo.FileName = $FilePath
    Write-Host "$FilePath $Arguments $PWD"
    if ($WorkingDirectory.Length -eq 0) {
        $ProcessInfo.WorkingDirectory = $PWD
    }
    else {
        $ProcessInfo.WorkingDirectory = $WorkingDirectory
    }
    #0x00000000 WindowStyle
    $ProcessInfo.Arguments = $Arguments
    $ProcessInfo.UseShellExecute = $false ## use createprocess not shellexecute
    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $ProcessInfo
    if ($Process.Start() -eq $false) {
        return -1
    }
    $Process.WaitForExit()
    return $Process.ExitCode
}


Function Update-Title {
    param(
        [String]$Title
    )
    if ($null -eq $Global:WindowTitleBase) {
        $Global:WindowTitleBase = $Host.UI.RawUI.WindowTitle
        $Host.UI.RawUI.WindowTitle = $Host.UI.RawUI.WindowTitle + $Title
    }
    else {
        $Host.UI.RawUI.WindowTitle = $Global:WindowTitleBase + $Title
    }
}

#$result=Update-Language -Lang 65001 # initialize language
Function Update-Language {
    param(
        [int]$Lang = 65001
    )
    $code = @'
[DllImport("Kernel32.dll")]
public static extern bool SetConsoleCP(int wCodePageID);
[DllImport("Kernel32.dll")]
public static extern bool SetConsoleOutputCP(int wCodePageID);

'@
    $wconsole = Add-Type -MemberDefinition $code -Name "WinConsole" -PassThru
    $result = $wconsole::SetConsoleCP($Lang)
    if (!$result) {
        Write-Host -ForegroundColor Red "Set Console Codepage error"
    }
    $result = $wconsole::SetConsoleOutputCP($Lang)
    if (!$result) {
        Write-Host -ForegroundColor Red "Set Console Output Codepage error"
    }
}

function Test-Executable {
    param(
        [String]$Command
    )
    if (!(Test-Path $Command)) {
        return $FALSE
    }
    $cmd = Get-Command -CommandType Application $Command -ErrorAction SilentlyContinue
    if ($null -eq $cmd) {
        return $false
    }
    return $true
}

function TestTcpConnection {
    Param(
        [string]$ServerName,
        $Port = 80
    )
    try {
        $ResponseTime = [System.Double]::MaxValue
        $tcpclient = New-Object system.Net.Sockets.TcpClient
        $stopwatch = New-Object System.Diagnostics.Stopwatch
        $stopwatch.Start()
        $tcpConnection = $tcpclient.BeginConnect($ServerName, $Port, $null, $null)
        $ConnectionSucceeded = $tcpConnection.AsyncWaitHandle.WaitOne(3000, $false)
        $stopwatch.Stop()
        $ResponseTime = $stopwatch.Elapsed.TotalMilliseconds
        if (!$ConnectionSucceeded) {
            $tcpclient.Close()
        }
        else {
            $tcpclient.EndConnect($tcpConnection) | Out-Null
            $tcpclient.Close()
        }
        return $ResponseTime
    }
    catch {
        return [System.Double]::MaxValue
    }
}


Function Test-BestSourcesURL {
    param(
        [String[]]$Urls
    )
    [System.Double]$pretime = [System.Double]::MaxValue
    [int]$index = 0
    for ($i = 0; $i -lt $Urls.Count; $i++) {
        $u = $Urls[$i]
        $xuri = [uri]$u
        $resptime = TestTcpConnection -ServerName $xuri.Host -Port $xuri.Port
        #if ($xuri.Host -eq "github.com") {
        #    $resptime += 1000 # Github AWS slow in china
        #}
        Write-Host "$u time: $resptime ms"
        if ($pretime -gt $resptime) {
            $index = $i
            $pretime = $resptime
        }
    }
    return $Urls[$index]
}