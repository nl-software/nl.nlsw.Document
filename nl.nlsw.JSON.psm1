#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.JSON.psm1
# @copyright Ernst van der Pols, Licensed under the EUPL-1.2-or-later
# @date 2022-08-09
#requires -version 5

<#
.SYNOPSIS
 JSON Document utility class.

.DESCRIPTION
 JSON (JavaScript Object Notation), specified by RFC 7159 (which obsoletes RFC 4627) and by ECMA-404,
 is a lightweight data interchange format inspired by JavaScript object literal syntax (although it
 is not a strict subset of JavaScript 1).

 Since class support in PowerShell 5.0 is still limited, we use it here
 only for declaration of some static JSON related data, with various
 static operations.
#>
class JsonDoc {

	# regex to match / replace an object name
	# @see https://stackoverflow.com/questions/32155133/regex-to-match-a-json-string (preceded with whitespace and followed by name-separator
	static $nameRegex = [System.Text.RegularExpressions.Regex]::New('(?<name>"(((?=\\)\\(["\\\/bfnrt]|u[0-9a-fA-F]{4}))|[^"\\\0-\x1F\x7F]+)*"):  ',"Compiled,CultureInvariant");

	# static constructor
	static JsonDoc() {
	}

}

<#
.SYNOPSIS
 Convert an object to a JSON-formatted string.

.DESCRIPTION
 Conversion of objects to JavaScript Object Notation (JSON) is in PowerShell
 supported via the ConvertTo-Json cmdlet.

 This function uses this cmdlet, but adds a few options to tweak the resulting output.

 Formats JSON in a nicer format than the built-in ConvertTo-Json does.


.PARAMETER InputObject
 The objects to convert to JSON format. Enter a variable that contains the objects, or type a command
 or expression that gets the objects. You can also pipe an object to ConvertTo-FormattedJson.

 The InputObject parameter is required, but its value can be null ($Null) or an empty string.
 When the input object is $Null, ConvertTo-FormattedJson does not generate any output.
 When the input object is an empty string, ConvertTo-FormattedJson returns an empty string.

.PARAMETER Compress
 Omit white space and indented formatting in the output string.

.PARAMETER Depth
 How many levels of contained objects are included in the JSON representation.
 The default value is 2.

.PARAMETER Tab
 Use a single TAB character for the indentation.
 By default, the 4 spaces of ConvertTo-Json are replaced with 2 spaces.
#>
function ConvertTo-FormattedJson {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
		[AllowNull()][AllowEmptyString()]
		$InputObject,

		[Parameter(Mandatory=$false)]
		[switch]$Compress,

		[Parameter(Mandatory=$false)]
		[int]$Depth = 2,

		[Parameter(Mandatory=$false)]
		[switch]$Tab
	)
	begin {
		$indentChar = if ($Tab) { "`t" } else { "  " }
	}
	process {
		$InputObject | ConvertTo-Json -Depth $Depth -Compress:$Compress | foreach-object {
			$json = $_
			if (!$Compress) {
				# Formats JSON in a nicer format than the built-in ConvertTo-Json does.
				# @see https://stackoverflow.com/questions/33145377/how-to-change-tab-width-when-converting-to-json-in-powershell
				$indent = 0;
				return ($json -Split "`n" | foreach-object {
					if ($_ -match '[\}\]]\s*,?\s*$') {
						# This line ends with ] or }, decrement the indentation level
						$indent--
					}
					$line = ($indentChar * $indent) + [JsonDoc]::nameRegex.Replace($_.TrimStart(), "`${name}: ", 1)
					if ($_ -match '[\{\[]\s*$') {
						# This line ends with [ or {, increment the indentation level
						$indent++
					}
					$line
				}) -Join "`n"
			}
			else {
				$json
			}
		}
	}
}


Export-ModuleMember -Function *
