param(
	[string]$Path="NNNN"
)
Function Test{
	Write-Host "Tets $Value ;$Path"
}

# $item_=Get-Childitem env:

# foreach($i in $item_){
# 	Write-Host $i.Name
# 	Write-Host $i.Value
# }
Test
$Value="Value"
Test