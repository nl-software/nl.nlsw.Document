#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.Process.Utility.psm1
# @date 2020-06-18
#requires -version 5

<#
.SYNOPSIS
 Shows the .NET assemblies that have been loaded into PowerShell.
#>

<#
.SYNOPSIS
 Get the architecture of the Windows operating system.
 Returns '32 bits' or '64 bits'
#>
function Get-OSArchitecture {
	(gwmi -Query "Select OSArchitecture from Win32_OperatingSystem").OSArchitecture
}

function Show-Assembly {
	write-host "Loaded .NET assemblies"
	[appdomain]::currentdomain.getassemblies() | sort -property fullname | format-table fullname | out-host
}
<#
.SYNOPSIS
 Shows the loaded PowerShell modules and snap-ins.
#>
function Show-Module {
	write-host "Loaded PowerShell Modules and Snap-Ins"
	Get-Module | out-host
	Get-PSSnapin | out-host
}
<#
.SYNOPSIS
 Shows the properties of an object.
#>
function Show-Object {
	param([object]$object)
	$object | select-object -property * | out-host
}
<#
.SYNOPSIS
 Writes a message to the host, indicating an action that has been or is going to be performed on an object.
#>
function Write-Action {
	param ([string]$action, [object]$object)
	write-host ("{0,16} {1}" -f $action,$object) -foregroundcolor "Yellow"
}

Export-ModuleMember -Function *
