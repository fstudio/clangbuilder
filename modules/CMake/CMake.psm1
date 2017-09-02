# CMake build 

Function CMakeInstallationFix {
    param(
        [String]$TargetDir,
        [String]$Configuration
    )
    ## Fix $(Configuration) to $Configuration
    Get-ChildItem -Path $TargetDir  -Recurse *.cmake | Foreach-Object {
        $content = Get-Content $_.FullName
        $content = $content.Replace("`$(Configuration)", "$Configuration")
        $content|Out-File $_.FullName
    }
}
