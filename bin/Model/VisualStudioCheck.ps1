

$SdkRoot="C:\Program Files (x86)\Windows Kits\10\Include"
$ProductVersion="10.0.14295"

$SdkItem=Get-ChildItem $SdkRoot
foreach($i in $SdkItem){
    if($i -imatch $ProductVersion){
      $ProductVersion=$i
    }
}
echo $ProductVersion
