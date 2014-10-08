
#Otjer Path 
<#
Many software modifies global environment variables of the wanton, the conflict is likely to cause the environment variable, 
In order to avoid conflict of environment variables, we have created a clean shell environment
#>
Function Global:Clear-EnvPath
{
$env:PATH="${env:SystemRoot}\System32;${env:SystemRoot};${env:SystemRoot}\System32\Wbem;${env:SystemRoot}\System32\WindowsPowerShell\v1.0\;"
}