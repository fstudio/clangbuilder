# CMake build

Function CMakeInstallationFix {
    param(
        [String]$TargetDir,
        [String]$Configuration
    )
    ## Fix $(Configuration) to $Configuration
    Get-ChildItem -Path $TargetDir  -Recurse *.cmake | ForEach-Object {
        $content = Get-Content $_.FullName
        $content = $content.Replace("`$(Configuration)", "$Configuration")
        $content | Out-File -FilePath $_.FullName -Encoding utf8
    }
}

Function CMakeFileflags {
    param(
        [String]$File,
        [Hashtable]$Table
    )
    if (!(Test-Path $File)) {
        return 
    }
    Write-Host "Find cmake flags file: $File"
    $cmakeflags = Get-Content -Path $File -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($null -eq $cmakeflags) {
        return 
    }
    foreach ($flag in $cmakeflags.CMake) {
        $fv = $flag.Split("=")
        $key = $fv[0]
        if ($Table.Contains($key)) {
            continue
        }
        if ($vv.Count -eq 2) {
            $Table[$key] = $flag
        }
        else {
            $Table[$key] = $flag
        }
    }
}


Function CMakeCustomflags {
    param(
        [String]$ClangbuilderRoot,
        [String]$Branch
    )

    [System.Text.StringBuilder]$fb = ""
    $flagtable = @{ }

    CMakeFileflags -File "$ClangbuilderRoot/out/cmakeflags.$Branch.json" -Table $flagtable
    CMakeFileflags -File "$ClangbuilderRoot/out/cmakeflags.json" -Table $flagtable
    foreach ($_ in $flagtable.Keys) {
        [void]$fb.Append(" ")
        [void]$fb.Append($flagtable.Item($_))
    }
    $flags = $fb.ToString()
    if ($flags.Length -gt 1) {
        Write-Host "New cmake flags: $flags"
    }
    return $flags
}