#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.Collections.psm1
# @date 2019-05-21
#requires -version 2

<#
.SYNOPSIS
 Convert an array of hashtables into a single hashtable.

.DESCRIPTION
 Convert an array of hashtables into a single hashtable. The value
 of an entry will be made an array, if multiple values are present.

.LINK
 https://devblogs.microsoft.com/scripting/dealing-with-powershell-hash-table-quirks/

.LINK
 ConvertFrom-StringData
#>
function ConvertFrom-HashtableArray {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[hashtable[]]$hashtables
	)
	begin {
		$result = @{}
	}
	process {
		# convert array of hashtables into a single hashtable
		foreach ($hashtable in $hashtables) {
			foreach ($entry in $hashtable.GetEnumerator()) {
				if ($result.ContainsKey($entry.Key)) {
					$value = $result[$entry.Key]
					if ($value -is [array]) {
						$result[$entry.Key] += $entry.Value
					}
					else {
						$result[$entry.Key] = @($value, $entry.Value)
					}
				}
				else {
					$result.Add($entry.Key, $entry.Value)
				}
			}
		}
	}
	end {
		return $result
	}
}

Export-ModuleMember -Function *
