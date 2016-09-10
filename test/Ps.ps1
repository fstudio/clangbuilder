
$item_=Get-Childitem env:

foreach($i in $item_){
	Write-Host $i.Name
	Write-Host $i.Value
}