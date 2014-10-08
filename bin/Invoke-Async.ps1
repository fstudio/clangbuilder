<#
.Synopsis
   A means of running multiple instances of a cmdlet/function/scriptblock
.DESCRIPTION
   This function allows you to provide a cmdlet, function or script block with a set of data to allow multithreading.
.EXAMPLE
   $sb = [scriptblock] {param($system) gwmi win32_operatingsystem -ComputerName $system | select csname,caption}
   $servers = Get-Content servers.txt
   $rtn = Invoke-Async -Set $server -SetParam system  -ScriptBlock $sb
.EXAMPLE
   $servers = Get-Content servers.txt
   $rtn = Invoke-Async -Set $servers -SetParam computername -Params @{count=1} -Cmdlet Test-Connection -ThreadCount 50 
.INPUTS
   
.OUTPUTS
   Determined by the provided cmdlet, function or scriptblock.
.NOTES
    This can often times eat up a lot of memory due in part to how some cmdlets work. Test-Connection is a good example of this. 
    Although it is not a good idea to manually run the garbage collector it might be needed in some cases and can be run like so:
    [gc]::Collect()
#>

function Invoke-Async{
param(
#The data group to process, such as server names.
[parameter(Mandatory=$true,ValueFromPipeLine=$true)]
[object[]]$Set,
#The parameter name that the set belongs to, such as Computername.
[parameter(Mandatory=$true)]
[string] $SetParam,
#The Cmdlet for Function you'd like to process with.
[parameter(Mandatory=$true, ParameterSetName='cmdlet')]
[string]$Cmdlet,
#The ScriptBlock you'd like to process with
[parameter(Mandatory=$true, ParameterSetName='ScriptBlock')]
[scriptblock]$ScriptBlock,
#any aditional parameters to be forwarded to the cmdlet/function/scriptblock
[hashtable]$Params,
#number of jobs to spin up, default being 10.
[int]$ThreadCount=10,
#return performance data
[switch]$Measure
)
Begin
{

    $Threads = @()
    $Length = $JobsLeft = $Set.Length

    $Count = 0
    if($Length -lt $ThreadCount){$ThreadCount=$Length}
    $timer = @(1..$ThreadCount  | ForEach-Object{$null})
    $Jobs = @(1..$ThreadCount  | ForEach-Object{$null})
    
    If($PSCmdlet.ParameterSetName -eq 'cmdlet')
    {
        $CmdType = (Get-Command $Cmdlet).CommandType
        if($CmdType -eq 'Alias')
        {
            $CmdType = (Get-Command (Get-Command $Cmdlet).ResolvedCommandName).CommandType
        }
        
        If($CmdType -eq 'Function')
        {
            $ScriptBlock = (Get-Item Function:\$Cmdlet).ScriptBlock
            1..$ThreadCount | ForEach-Object{ $Threads += [powershell]::Create().AddScript($ScriptBlock)}
        }
        ElseIf($CmdType -eq "Cmdlet")
        {
            1..$ThreadCount  | ForEach-Object{ $Threads += [powershell]::Create().AddCommand($Cmdlet)}
        }
    }
    Else
    {
        1..$ThreadCount | ForEach-Object{ $Threads += [powershell]::Create().AddScript($ScriptBlock)}
    }

    If($Params){$Threads | ForEach-Object{$_.AddParameters($Params) | Out-Null}}

}
Process
{
    while($JobsLeft)
    {
        for($idx = 0; $idx -lt ($ThreadCount-1) ; $idx++)
        {
            $SetParamObj = $Threads[$idx].Commands.Commands[0].Parameters| Where-Object {$_.Name -eq $SetParam}
             
            If($Jobs[$idx].IsCompleted) #job ran ok, clear it out
            {  
                $result = $null
                if($threads[$idx].InvocationStateInfo.State -eq "Failed")
                {
                    $result  = $Threads[$idx].InvocationStateInfo.Reason
                    Write-Error "Set Item: $($SetParamObj.Value) Exception: $result"
                }
                else
                { 
                    $result = $Threads[$idx].EndInvoke($Jobs[$idx])
                }
                $ts = (New-TimeSpan -Start $timer[$idx] -End (Get-Date))
                if($Measure)
                {
                    new-object psobject -Property @{
                        TimeSpan = $ts
                        Output = $result
                        SetItem = $SetParamObj.Value}
                }
                else
                {
                    $result
                }
                $Jobs[$idx] = $null
                $JobsLeft-- #one less left
                write-verbose "Completed: $($SetParamObj.Value) in $ts"
                write-progress -Activity "Processing Set" -Status "$JobsLeft jobs left" -PercentComplete (($length-$jobsleft)/$length*100)
            }
            If(($Count -lt $Length) -and ($Jobs[$idx] -eq $null)) #add job if there is more to process
            {
                write-verbose "starting: $($Set[$Count])"
                $timer[$idx] = get-date
                $Threads[$idx].Commands.Commands[0].Parameters.Remove($SetParamObj) | Out-Null #check for success?
                $Threads[$idx].AddParameter($SetParam,$Set[$Count]) | Out-Null
                $Jobs[$idx] = $Threads[$idx].BeginInvoke()
                $Count++
            }
        }

    }
}
End
{
    $Threads | ForEach-Object{$_.runspace.close();$_.Dispose()}
}
}

Export-ModuleMember -Function Invoke-Async