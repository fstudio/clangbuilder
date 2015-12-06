Function Parser-IniFile
{
    param(
        [Parameter(Position=0,Mandatory=$True,HelpMessage="Enter Your Ini File Path")]
        [ValidateNotNullorEmpty()]
        [String]$File
        )
    $ini = @{}
    $section = "NO_SECTION"
    $ini[$section] = @{}
    switch -regex -file $File {
        "^\[(.+)\]$" {
            $section = $matches[1].Trim()
            $ini[$section] = @{}
        }
        "^\s*([^#].+?)\s*=\s*(.*)" {
            $name,$value = $matches[1..2]
            # skip comments that start with semicolon:
            if (!($name.StartsWith(";"))) {
                $ini[$section][$name] = $value.Trim()
            }
        }
    }
    $ini
}

$IniAttr=Parser-IniFile -File "${PrefixDir}/repositories.ini"
$StdoutFile=$IniAttr["Windows"]["stdout"]


