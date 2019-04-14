##  LLVM sources module



Function DownloadFile {
    param(
        [String]$URI
    )
    Write-Debug "$URI"
}

Function UnpackFile {
    param(
        [String]$File, # Filename
        [String]$Path,
        [String]$OldName,
        [String]$Name
    )
    Write-Host "Unpack File '$Path\$File'"
}

##
Function LLVMDownload {
    param(
        [Switch]$LLDB
    )
    # Fix TLS
    if ($PSEdition -eq "Desktop") {
        $AllProtocols = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
        [System.Net.ServicePointManager]::SecurityProtocol = $AllProtocols
    }
}

Function LLVMRemoteFetch {
    param(
        [String]$Branch = "master",
        [Switch]$LLDB
    )
}

Function Update-LLVM {
    param(
        [string]$Branch,
        [string]$ClangbuilderRoot
    )
    Write-Host "Update LLVM $Branch"

}

