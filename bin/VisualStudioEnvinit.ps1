#!/usr/bin/env poewershell
# Initialize Visual Studio Environment
param (
    [ValidateSet("x86", "x64", "ARM", "ARM64")]
    [String]$Arch="x64",
    [ValidateSet("110", "120", "140", "141", "150")]
    [String]$VisualStudio="140"
)
