#!/usr/bin/env pwsh

param(
    [String]$Path
)

Function Initialize-FlatTarget {
    param(
        [String]$TopDir,
        [String]$MoveTo
    )
    $items = Get-ChildItem -Path $TopDir
    if ($items.Count -ne 1) {
        return 
    }
    if ($items[0] -isnot [System.IO.DirectoryInfo]) {
        Write-Host "done is not dir"
        return ;
    }
    $childdel = $items[0].FullName
    $checkdir = $childdel
    for ($i = 0; $i -lt 10; $i++) {
        $childs = Get-ChildItem $checkdir
        if ($childs.Count -eq 1 -and $childs[0] -is [System.IO.DirectoryInfo]) {
            $checkdir = $childs[0].FullName
            continue;
        }
        Move-Item -Force -Path "$checkdir/*" -Destination $MoveTo
        Remove-Item -Force -Recurse $childdel
        Write-Host "move '$checkdir/*' to '$MoveTo' done"
        return 
    }
    Write-Host "unable resolve $checkdir"
}
Initialize-FlatTarget -TopDir $Path -MoveTo $Path