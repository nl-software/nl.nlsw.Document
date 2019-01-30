#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.Process.Utility.ps1
# @date 2019-01-30
#requires -version 5

<#
.SYNOPSIS
 Create a new folder in the specified base folder.

.DESCRIPTION
 The new folder has a GUID as name.
#>
function New-TempFolder {
	param ([string] $base)
	$Guid = [System.Guid]::NewGuid().ToString()
	$TempFolder = $(Join-Path $base $Guid)
	return New-Item -Type Directory -Path $TempFolder
}
<#
.SYNOPSIS
 Remove the specified folder.

.DESCRIPTION
 The folder was created with New-TempFolder.
#>
function Remove-TempFolder {
	param ([string] $folder)
	Push-Location $folder
	Remove-Item '*.*' -Recurse -Force 
	Pop-Location
	Remove-Item $folder
}
<#
.SYNOPSIS
 Shows the .NET assemblies that have been loaded into PowerShell.
#>
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
