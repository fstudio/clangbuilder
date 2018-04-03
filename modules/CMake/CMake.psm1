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
        $content|Out-File -FilePath $_.FullName -Encoding utf8
    }
}

Function CMakeFileflags {
    param(
        [String]$File,
        [Hashtable]$Table
    )
    if (Test-Path $File) {
        try {
            Write-Host "Find cmake flags file: $File"
            $cmakeflags = Get-Content -Path $File|ConvertFrom-JSON
            foreach ($flag in $cmakeflags.CMake) {
                $vv = $flag.Split("=")
                if ($Table.Contains($vv[0])) {
                    continue
                }
                if ($vv.Count -eq 2) {
                    $Table[$vv[0]] = $flag
                }
                else {
                    $Table[$flag] = $flag
                }
            }
        }
        catch {
            Write-Host -ForegroundColor Red "Parse error $_"
            return 
        }
    }
}

Function CMakeCustomflags {
    param(
        [String]$ClangbuilderRoot,
        [String]$Branch
    )
    $flags = ""
    $vflags = @{}
    CMakeFileflags -File "$ClangbuilderRoot/out/cmakeflags.$Branch.json" -Table $vflags
    CMakeFileflags -File "$ClangbuilderRoot/out/cmakeflags.json" -Table $vflags
    foreach ($_ in $vflags.Keys) {
        $flags += " " + $vflags.Item($_)
    }

    if ($flags.Length -gt 1) {
        Write-Host "New cmake flags: $flags"
    }
    return $flags
}