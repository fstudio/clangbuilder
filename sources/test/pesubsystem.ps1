#

param(
    [String]$Path
)

$xpath = $Path.Replace("/", "\")
$a = $((dumpbin /HEADERS $xpath | ? { $_.Contains("3 subsystem (Windows CUI)") })) ## ''  

if($a.Length -ne 0){
    Write-Host "$xpath subsystem is windows cui"
}else{
    Write-Host "$xpath subsystem not windows cui"
}
