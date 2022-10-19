#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.Items.psm1
# @copyright Ernst van der Pols, Licensed under the EUPL-1.2-or-later
# @date 2020-10-12
#requires -version 5

<#
.SYNOPSIS
 Expand macros in a string with properties of the specified ItemObject.

.DESCRIPTION
 The macro syntax is:
		'{' [<pre> '<'] <key> ['>' <post>] ['|' <empty>] '}'

 with
	<pre>	text to put in front of the macro value if the value is not empty
	<key>	the macro identifier
	<post>	text to put after the macro value if the value is not empty
	<empty>	text to output if the macro value is empty

 Available macro key values (case insensitive):
 - NAME		replaced by the name of the ItemObject
 - ID		replaced by the identifier of the ItemObject
 - UUID		replaced by the UUID of the ItemObject

.PARAMETER ItemObject
 The ItemObject to get the properties of.

.PARAMETER Text
 The string to replace macros in. May be piped.

.INPUTS
 System.String

.OUTPUTS
 System.String
#>
function Expand-ItemObjectMacro {
	[CmdletBinding()]
	[OutputType([System.String])]
	param (
		[Parameter(Mandatory=$true)]
		[nl.nlsw.Items.ItemObject]$item,

		[Parameter(Mandatory=$true, ValueFromPipeline = $true, ValueFromPipelinebyPropertyName = $true)]
		[string]$text
	)
	process {
		[nl.nlsw.Document.Utility]::PathMacroRegex.Replace($text,{
			$value = $item.GetMacroValue($args[0].groups['key']);
			if ($value) {
				"$($args[0].groups['pre'])$($value)$($args[0].groups['post'])"
			}
			else {
				$args[0].groups['empty']
			}
		})
	}
}

Export-ModuleMember -Function *
