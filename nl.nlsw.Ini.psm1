#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.Ini.psm1
# @copyright Ernst van der Pols, Licensed under the EUPL-1.2-or-later
# @date 2021-09-30
#requires -version 3

<#
.SYNOPSIS
	Gets the content of an INI file

.DESCRIPTION
	Gets the content of an INI file and returns it as an ordered hashtable.

.INPUTS
	System.String

.OUTPUTS
	System.Collections.Specialized.OrderedDictionary

.PARAMETER Path
	Specifies the path to the input file.

.EXAMPLE
	$FileContent = Import-Ini "C:\myinifile.ini"
	-----------
	Description
	Saves the content of the c:\myinifile.ini in a hashtable called $FileContent

.EXAMPLE
	$inifilepath | $FileContent = Import-Ini
	-----------
	Description
	Gets the content of the ini file passed through the pipe into a hashtable called $FileContent

.EXAMPLE
	C:\PS>$FileContent = Import-Ini "c:\settings.ini"
	C:\PS>$FileContent["Section"]["Key"]
	-----------
	Description
	Returns the key "Key" of the section "Section" from the C:\settings.ini file

.LINK
	Export-Ini

.LINK
	https://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91

.NOTES
	Author  : Oliver Lipkau <oliver@lipkau.net>
	Blog    : http://oliver.lipkau.net/blog/
	Original: Get-IniContent
	Source  : https://github.com/lipkau/PsIni
			  http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
	Version : 1.0 - 2010/03/12 - Initial release
			  1.1 - 2014/12/11 - Typo (Thx SLDR)
								 Typo (Thx Dave Stiff)

	#Requires -Version 2.0
#>
function Import-Ini {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        #[ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [string]$Path
    )
    begin {
	}
    process {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: importing $Path"

        $ini = [ordered]@{}
        switch -regex -file $Path
        {
            "^\[(.+)\]$" # Section
            {
				if ($section)
				{
					if ($CommentCount -gt 0)
					{
						$ini[$section][';CommentCount'] = $CommentCount
					}
				}
                $section = $matches[1]
                $ini[$section] = [ordered]@{}
                $CommentCount = 0
            }
            "^;(.*)$" # Comment
            {
                if (!($section))
                {
                    $section = "No-Section"
                    $ini[$section] = [ordered]@{}
                    $CommentCount = 0
                }
                $value = $matches[1]
                $CommentCount = $CommentCount + 1
                $name = ";Comment" + $CommentCount
                $ini[$section][$name] = $value
            }
            "(.+?)\s*=\s*(.*)" # Key
            {
                if (!($section))
                {
                    $section = "No-Section"
                    $ini[$section] = [ordered]@{}
                    $CommentCount = 0
                }
                $name,$value = $matches[1..2]
                $ini[$section][$name] = $value
            }
        }
		if ($section)
		{
			if ($CommentCount -gt 0)
			{
				$ini[$section][';CommentCount'] = $CommentCount
			}
		}

        Write-Verbose "$($MyInvocation.MyCommand.Name)::  imported $($ini.Keys.Count) ini sections"
        return $ini
    }
    end {
	}
}

<#
.SYNOPSIS
	Write hashtable content to INI file

.DESCRIPTION
	Write hashtable content to INI file

.INPUTS
	System.String
	System.Collections.Hashtable

.OUTPUTS
	System.IO.FileSystemInfo

.PARAMETER Append
	Adds the output to the end of an existing file, instead of replacing the file contents.

.PARAMETER InputObject
	Specifies the Hashtable to be written to the file. Enter a variable that contains the objects or type a command or expression that gets the objects.

.PARAMETER Path
	Specifies the path to the output file.

 PARAMETER Encoding
	Specifies the type of character encoding used in the file. Valid values are "Unicode", "UTF7",
	 "UTF8", "UTF32", "ASCII", "BigEndianUnicode", "Default", and "OEM". "Unicode" is the default.

	"Default" uses the encoding of the system's current ANSI code page.

	"OEM" uses the current original equipment manufacturer code page identifier for the operating
	system.

.PARAMETER Force
	Allows the cmdlet to overwrite an existing read-only file. Even using the Force parameter, the cmdlet cannot override security restrictions.

.PARAMETER PassThru
	Passes an object representing the location to the pipeline. By default, this cmdlet does not generate any output.

.EXAMPLE
	Export-Ini $IniVar "C:\myinifile.ini"
	-----------
	Description
	Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini

.EXAMPLE
	$IniVar | Export-Ini "C:\myinifile.ini" -Force
	-----------
	Description
	Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and overwrites the file if it is already present

.EXAMPLE
	$file = Export-Ini $IniVar "C:\myinifile.ini" -PassThru
	-----------
	Description
	Saves the content of the $IniVar Hashtable to the INI File c:\myinifile.ini and saves the file into $file

.EXAMPLE
	$Category1 = @{"Key1"="Value1";"Key2"="Value2"}
	$Category2 = @{"Key1"="Value1";"Key2"="Value2"}
	$NewINIContent = @{"Category1"=$Category1;"Category2"=$Category2}
	Export-Ini -InputObject $NewINIContent -Path "C:\MyNewFile.INI"
	-----------
	Description
	Creating a custom Hashtable and saving it to C:\MyNewFile.INI

.LINK
	Import-Ini

.LINK
	https://github.com/lipkau/PsIni

.NOTES
	Author        : Oliver Lipkau <oliver@lipkau.net>
	Blog        : http://oliver.lipkau.net/blog/
	Original : Out-IniFile
	Source        : https://github.com/lipkau/PsIni
	Version        : 1.0 - 2010/03/12 - Initial release
				  1.1 - 2012/04/19 - Bugfix/Added example to help (Thx Ingmar Verheij)
				  1.2 - 2014/12/11 - Improved handling for missing output file (Thx SLDR)

	#Requires -Version 2.0
#>
function Export-Ini {
    [CmdletBinding()]
	[OutputType([System.IO.FileSystemInfo])]
    param(
        [switch]$Append,

        [ValidateSet("Unicode","UTF7","UTF8","UTF32","ASCII","BigEndianUnicode","Default","OEM")]
        [Parameter()]
        [string]$Encoding = "UTF8",


        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^([a-zA-Z]\:)?.+\.ini$')]
        [Parameter(Mandatory=$True)]
        [string]$Path,

        [switch]$Force,

        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [Hashtable]$InputObject,

        [switch]$Passthru
    )

    begin  {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"
	}

    process {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing to file: $Path"

        if ($append) {
			$outfile = Get-Item $Path
		}
        else {
			$outFile = New-Item -ItemType file -Path $Path -Force:$Force
		}
        if (!($outFile)) {
			throw "Could not create File"
		}
        foreach ($i in $InputObject.keys)
        {
            if (!($($InputObject[$i].GetType().Name) -eq "Hashtable"))
            {
                #No Sections
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $i"
                Add-Content -Path $outFile -Value "$i=$($InputObject[$i])" -Encoding $Encoding
            }
			else {
                #Sections
                Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing Section: [$i]"
                Add-Content -Path $outFile -Value "[$i]" -Encoding $Encoding
                Foreach ($j in $($InputObject[$i].keys | Sort-Object))
                {
                    if ($j -match "^;Comment[\d]+") {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing comment: $j"
                        Add-Content -Path $outFile -Value ";$($InputObject[$i][$j])" -Encoding $Encoding
                    } else {
                        Write-Verbose "$($MyInvocation.MyCommand.Name):: Writing key: $j"
                        Add-Content -Path $outFile -Value "$j=$($InputObject[$i][$j])" -Encoding $Encoding
                    }

                }
                Add-Content -Path $outFile -Value "" -Encoding $Encoding
            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Writing to file: $path"
        if ($PassThru) {return $outFile}
    }

    end {
		Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"
	}
}

Export-ModuleMember -Function *
