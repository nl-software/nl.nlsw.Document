#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.Process.Utility.psm1
# @copyright Ernst van der Pols, Licensed under the EUPL-1.2-or-later
# @date 2022-10-19
#requires -version 5

<#
.SYNOPSIS
 Get the architecture of the Windows operating system.
 Returns '32-bit' or '64-bit'
#>
function Get-OSArchitecture {
	return $(if ([System.Environment]::Is64BitOperatingSystem) { "64-bit" } else { "32-bit" })
}

<#
.SYNOPSIS
 Get the .NET assemblies (by name) that have been loaded into this PowerShell session.
#>
function Get-Assembly {
	[AppDomain]::CurrentDomain.GetAssemblies() | Sort-Object -property FullName | ForEach-Object { $_.FullName }
}

<#
.SYNOPSIS
 Get the properties of an object.
#>
function Get-ObjectProperty {
	param([object]$object)
	$object | select-object -property *
}

Export-ModuleMember -Function *
