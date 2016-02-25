<#
Expand Archive base 7z, support other file format
#>

Function Expand-Archive7{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Compressed File")]
        [ValidateNotNullorEmpty()]
        [String]$File,
        [Parameter(Position=1,Mandatory=$True,HelpMessage="Uncompress Folder")]
        [ValidateNotNullorEmpty()]
        [String]$Destination
    )
}

Function Compress-Archive7{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Compress Path")]
        [ValidateNotNullorEmpty()]
        [String]$Path,
        [Parameter(Position=1,Mandatory=$True,HelpMessage="Compressed File output Path")]
        [ValidateNotNullorEmpty()]
        [String]$Destination
    )
}
