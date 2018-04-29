$ClangbuilderRoot = Split-Path (Split-Path -Parent $PSScriptRoot)
Import-Module "$ClangbuilderRoot\modules\Launcher"
Import-Module -Name "$ClangbuilderRoot\modules\Devinstall" # Package Manager
Import-Module "$ClangbuilderRoot\modules\VisualStudio"
$ret = DevinitializeEnv -ClangbuilderRoot $ClangbuilderRoot -Pkglocksdir "$ClangbuilderRoot/bin/pkgs/.locks"
if ($ret -ne 0) {
    # Need vswhere
    exit 1
}
$ret = DefaultVisualStudio -ClangbuilderRoot $ClangbuilderRoot # initialize default visual studio
if ($ret -ne 0) {
    Write-Host -ForegroundColor Red "Not found valid installed visual studio."
    exit 1
}
MakeLauncher -Cbroot $ClangbuilderRoot -Name "python" -Path "$ClangbuilderRoot\bin\pkgs\python3\python.exe"