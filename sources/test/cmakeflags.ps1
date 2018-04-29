
$ClangbuilderRoot = Split-Path (Split-Path -Parent $PSScriptRoot)
Import-Module "$ClangbuilderRoot\modules\CMake"

# Mainline
$s1=CMakeCustomflags -ClangbuilderRoot $ClangbuilderRoot -Branch "Mainline"
$s2=CMakeCustomflags -ClangbuilderRoot $ClangbuilderRoot -Branch "Release"
$s3=CMakeCustomflags -ClangbuilderRoot $ClangbuilderRoot -Branch "Stable"

Write-Host "[$s1][$s2][$s3]"