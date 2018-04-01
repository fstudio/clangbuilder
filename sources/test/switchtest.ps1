
param(
 [Switch]$Info
)

Function Fun1{ 
 param(
  [Switch]$Info
 )
 if($Info){
    Write-Host "True"
 }else{
    Write-Host "False"
 }
}

Fun1 -Info:$Info
