#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.Collections.psm1
# @copyright Ernst van der Pols, Licensed under the EUPL-1.2-or-later
# @date 2022-10-18
#requires -version 3

class nlswCollections {

	# Recursively, converts a dictionary (e.g. Hashtable or OrderedDictionary) to an OrderedDictionary.
	# @param $object the object to convert
	# @param $recurse convert member dictionaries as well
	# @param $sort sort the keys in the resulting dictionary
	# @return the OrderedDictionary with key/values if present, $null if object is $null
	static [System.Collections.Specialized.OrderedDictionary] ConvertDictionaryToOrderedDictionary([System.Collections.IDictionary]$object, [bool]$recurse, [bool]$sort) {
		if ($object) {
			$result = [ordered]@{}
			$keys = $object.Keys
			if ($sort) {
				$keys = $keys | Sort-Object
			}
			foreach ($key in $keys) {
				$value = $object.$key;
				if ($recurse -and ($value -is [System.Collections.IDictionary])) {
					$value = [nlswCollections]::ConvertDictionaryToOrderedDictionary($value, $recurse, $sort)
				}
				$result.Add($key, $value);
			}
			return $result;
		}
		return $null;
	}

	# Recursively, converts a PSObject as e.g. returned by ConvertFrom-Json to an OrderedDictionary.
	# @param $object the object to convert
	# @return the OrderedDictionary with key/values if present, $null if object is $null
	static [System.Collections.Specialized.OrderedDictionary] ConvertPSObjectToOrderedDictionary([PSObject]$object, [bool]$recurse, [bool]$sort) {
		if ($object) {
			$result = [ordered]@{}
			# convert PSObject to ordered hashtable
			$keys = $object.PSObject.Properties.Name
			if ($sort) {
				$keys = $keys | Sort-Object
			}
			foreach ($key in $keys) {
				$value = $object.$key;
				if ($recurse -and ($value -is [PSObject])) {
					$value = [nlswCollections]::ConvertPSObjectToOrderedDictionary($value, $recurse, $sort)
				}
				$result.Add($key, $value);
			}
			return $result;
		}
		return $null;
	}
}

<#
.SYNOPSIS
 Convert an array of hashtables into a single hashtable.

.DESCRIPTION
 Convert an array of hashtables into a single hashtable. The value
 of an entry will be made an array, if multiple values are present.

.INPUT
 System.Collections.Hashtable[]

.OUTPUT
 System.Collections.Hashtable

.LINK
 https://devblogs.microsoft.com/scripting/dealing-with-powershell-hash-table-quirks/

.LINK
 ConvertFrom-StringData
#>
function ConvertFrom-HashtableArray {
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
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

<#
.SYNOPSIS
 Convert an Array, Hashtable (or other IDictionary), or PSObject to an OrderedDictionary.

.DESCRIPTION
 Convert an object to an System.Collections.Specialized.OrderedDictionary,
 a.k.a. an ordered hashtable, given its PowerShell type accelerator notation
 '[ordered]@{}'.

 The following input object types are supported:
 - System.Array
   The index numbers are used as keys

 - System.Collections.IDictionary
   Key-value pairs are copied in natural order.
   With the $Sort switch specified, the keys are sorted.
   With the $Recurse switch specified, IDictionary members are recursively converted as well.

 - System.Collections.Specialized.OrderedDictionary
   Is returned as-is.

 - System.Management.Automation.PSObject
   Property members are copied in natural order.
   With the $Sort switch specified, the keys are sorted.
   With the $Recurse switch specified, members of type PSObject
   are recursively converted as well.

.PARAMETER InputObject
 The object to convert

.PARAMETER Recurse
 Recursively convert member values of the input object as well.

.PARAMETER Sort
 Sort the key values of the resulting dictionary

.INPUT
 System.Array
 System.Collections.IDictionary
 System.Management.Automation.PSObject

.OUTPUT
 System.Collections.Specialized.OrderedDictionary

.LINK
 https://devblogs.microsoft.com/scripting/convertto-ordereddictionary/

.LINK
 https://www.powershellgallery.com/packages/PoshFunctions/2.2.1.2/Content/Functions%5CConvertTo-OrderedDictionary.ps1
#>
function ConvertTo-OrderedDictionary {
	[CmdletBinding()]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Recurse', Justification="false positive")]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Sort', Justification="false positive")]
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[object]$InputObject,

		[Parameter(Mandatory=$false)]
		[switch]$Recurse,

		[Parameter(Mandatory=$false)]
		[switch]$Sort
	)
	begin {
	}
	process {
		$InputObject | where-object { $_ } | foreach-object {
			$object = $_
			if ($object -is [PSObject]) {
				# convert PSObject to ordered dictionary
				[nlswCollections]::ConvertPSObjectToOrderedDictionary($object, $Recurse, $Sort)
			}
			elseif ($object -is [System.Array]) {
				$result = [ordered]@{}
				for ($i = 0; $i -lt $object.Count; $i++) {
					$result.Add($i, $object[$i])
				}
				$result
			}
			elseif ($object -is [System.Collections.IDictionary]) {
				# convert IDictionary to ordered dictionary
				[nlswCollections]::ConvertDictionaryToOrderedDictionary($object, $Recurse, $Sort)
			}
			else {
				throw [NotSupportedException]::new(("cannot convert '{0}' to an ordered hashtable" -f $_))
			}
		}
	}
	end {
	}
}

Export-ModuleMember -Function *
