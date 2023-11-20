<#
.SYNOPSIS
 Run the PSScriptAnalyzer on this module.

.DESCRIPTION
 Runs a static analysis of the module.

 Rules excluded:
 - PSReviewUnusedParameter https://github.com/PowerShell/PSScriptAnalyzer/issues/1472

.NOTES
 @date 2022-10-20
 @author Ernst van der Pols
#>
#
# @file Debug-PSModule.ps1
# @note this file must be UTF8-with-BOM, otherwise Windows PS does not consider it Unicode.
#
#requires -version 5.1

[CmdletBinding()]
param (
	$mpath = $(Join-Path $PSScriptRoot "..")
)
begin {
	Add-Type -Path $mpath/lib/netstandard2.0/nl.nlsw.Document.dll
	Invoke-ScriptAnalyzer $(Join-Path $PSScriptRoot "..") -Recurse -Exclude PSReviewUnusedParameter
}
process {
}
end {
}
