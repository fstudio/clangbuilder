### Launcher modules


# create launcher
Function MakeLauncher {
    param(
        [String]$Cbroot,
        [String]$Name,
        [String]$Path
    )
    $BlastFile = "$Cbroot\bin\blast.exe"
    if (!(Test-Path $BlastFile)) {
        return $false
    }
    $SrcFile = $Path.Replace("/", "\")
    $builddir = $env:TEMP + "\$Name.$pid"
    New-Item -ItemType Directory $builddir -Force|Out-Null
    $origindir = Get-Location
    Set-Location $builddir
    $CCFile = "$Cbroot/sources/template/link.template.windows.cc"
    $obj = &$BlastFile --dump $Path|ConvertFrom-Json
    $IsConsole=$false
    if ($obj -ne $null -and $obj.Subsystem -ne $null -and $obj.Subsystem -eq "Windows CUI") {
        $IsConsole=$true
        $CCFile = "$Cbroot/sources/template/link.template.console.cc"
    }
    $epath = $SrcFile.Replace("\", "\\");
    $content = [System.IO.File]::ReadAllText("$CCFile").Replace("@LINK_TEMPLATE_TARGET", "$epath")
    [System.IO.File]::WriteAllText("$builddir\$Name.cc", $content)
    # replace resources info
    try {
        $versioninfo = (Get-Item $SrcFile).VersionInfo
        $rcontent = [System.IO.File]::ReadAllText("$Cbroot/sources/template/link.template.rc");
        $rcontent = $rcontent.Replace("@CompanyName", $versioninfo.CompanyName)
        $rcontent = $rcontent.Replace("@FileDescription", $versioninfo.FileDescription)
        $rcontent = $rcontent.Replace("@FileVersion", $versioninfo.FileVersion)
        $rcontent = $rcontent.Replace("@InternalName", $versioninfo.InternalName)
        if ($versioninfo.LegalCopyright -ne $null) {
            $LegalCopyright = $versioninfo.LegalCopyright.Replace("(c)", "\xA9").Replace("(C)", "\xA9")
            $rcontent = $rcontent.Replace("@LegalCopyright", $LegalCopyright)
        }
        else {
            $rcontent = $rcontent.Replace("@LegalCopyright", "No checked copyright")
        }

        $rcontent = $rcontent.Replace("@OriginalFilename", $versioninfo.OriginalFilename)
        $rcontent = $rcontent.Replace("@ProductName", $versioninfo.ProductName)
        $rcontent = $rcontent.Replace("@ProductVersion", $versioninfo.ProductVersion)

        $rcontent = $rcontent.Replace("@FileMajorPart", $versioninfo.FileMajorPart)
        $rcontent = $rcontent.Replace("@FileMinorPart", $versioninfo.FileMinorPart)
        $rcontent = $rcontent.Replace("@FileBuildPart", $versioninfo.FileBuildPart)
        $rcontent = $rcontent.Replace("@FilePrivatePart", $versioninfo.FilePrivatePart)

        Get-command -CommandType Application "mt.exe" -ErrorAction SilentlyContinue -ErrorVariable +myErr|Out-Null
        if ($myErr.count -eq 0) {
            mt /nologo "-inputresource:$SrcFile" "-out:$Name.manifest"
            if ($LASTEXITCODE -eq 0 -and (Test-Path "$Name.manifest")) {
                # https://msdn.microsoft.com/en-us/library/windows/desktop/aa374191(v=vs.85).aspx
                $rcontent = $rcontent.Replace("//@MANIFEST", "1 RT_MANIFEST `"$Name.manifest`"")
            }
        }
        $rcontent|Out-File -FilePath "$Name.rc" -Encoding unicode
        rc /nologo "$Name.rc"|Out-Host
        cl /nologo /Os "$Name.cc" /c|Out-Host
        Write-Host "link $Name to exe"
        if($IsConsole){
            link /nologo /NODEFAULTLIB /SUBSYSTEM:CONSOLE /ENTRY:wmain "$Name.obj" "$Name.res" Shell32.lib kernel32.lib user32.lib "/OUT:$Name.exe"|Out-Host
        }else{
            link /nologo /NODEFAULTLIB /SUBSYSTEM:WINDOWS /ENTRY:wWinMain "$Name.obj" "$Name.res" Shell32.lib kernel32.lib user32.lib  "/OUT:$Name.exe"|Out-Host
        }
        Move-Item "$Name.exe" -Force -Destination "$Cbroot/bin/pkgs/.linked/$Name.exe"
    }
    catch {
        Write-Host -ForegroundColor Red "$_"
        Set-Location $origindir
        if(Test-Path $builddir){
            Remove-Item -Force -Recurse $builddir  -ErrorAction SilentlyContinue |Out-Null
        }
        return $false
    }
    #
    Set-Location $origindir
    if(Test-Path $builddir){
        Remove-Item -Force -Recurse $builddir  -ErrorAction SilentlyContinue |Out-Null
    }
    return $true
}