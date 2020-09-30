#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.FileSystem.psm1
# @date 2020-04-27
#requires -version 5

<#
.SYNOPSIS
 Create a new unique output file name from the specified path.
 
.DESCRIPTION
 The input Path is expanded to an absolute path, the directory (folder) is
 created if not already exsiting, and the filename is made unique if
 necessary by appending "(<n>)" to the base filename, where "<n>" is
 a decimal number.
 Invalid filename characters in the input are replaced by an underscore '_'.

.PARAMETER Path
 The path to make a unique output file name from.
#>
function New-IncrementalFileName {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline = $true, ValueFromPipelinebyPropertyName = $true)]
		[string]$Path
	)
	begin {
		# convert any (range of) invalid filename characters to '_'
		$invalidFileCharRegEx = [regex]"[$([string]([System.IO.Path]::GetInvalidPathChars()))\*\?]+"
	}
	process {
		# convert any (range of) invalid filename characters to '_'
		# and determine absolute path, to avoid difference between Environment.CurrentDirectory i.s.o. $pwd
		$filepath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($(Get-Location),$invalidFileCharRegEx.Replace($Path,"_")))
		# create folder, if non-existing
		$filefolder = [System.IO.Path]::GetDirectoryName($filepath)
		if (!(test-path $filefolder)) {
			new-item -path $filefolder -itemtype Directory | out-null
		}
		# make output file unique with "(n)" extension
		if (test-path $filepath) {
			$name = [System.IO.Path]::GetFileNameWithoutExtension($filepath)
			$ext = [System.IO.Path]::GetExtension($filepath)
			$i = 0;
			do {
				$i++
				$filepath = [System.IO.Path]::Combine($filefolder,"$name($i)$ext")
			} while (test-path $filepath)
		}
		return $filepath
	}
}

<#
.SYNOPSIS
 Create a new folder in the specified base folder.

.DESCRIPTION
 The new folder has a GUID as name.
#>
function New-TempFolder {
	param ([string] $base = ".")
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
 Remove a file system item to the recycle bin, with or without confirmation dialog.

.DESCRIPTION
 Replacement of Remove-Item in case you want a file or folder to be moved to the
 recycle bin. This function uses the VisualBasic operations of .NET for the implementation.

.PARAMETER Path
 The path name of the item(s) to remove.
 
.PARAMETER PassThru
 Outputs the FileSystemInfo object of the original item if the file system item has been removed
 to the recycle bin. NOTE that this item is no longer at its original location, so use the object with care.

.INPUTS
 string
 
.OUTPUTS
 System.IO.FileSystemInfo

.LINK
 https://www.powershellgallery.com/packages/Recycle/1.0.2/Content/Recycle.psm1

.NOTES
 This code is based on the Recycle PS module of Brian Dukes.
 This function supports the ShouldProcess feature https://vexx32.github.io/2018/11/22/Implementing-ShouldProcess/
#>
function Remove-ItemToRecycleBin {
	[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
	param ( 
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[string[]]$Path,
		
		[switch]$PassThru
	)
	begin {
		$shell = new-object -comobject "Shell.Application"
	}
	process {
		if ($PSCmdlet.ShouldProcess($Path)) {
			$item = Get-Item $Path -ErrorAction "Stop"
			$fullpath = $item.FullName
			$directoryPath = Split-Path $item -Parent
			$shellFolder = $shell.Namespace($directoryPath)
			$shellItem = $shellFolder.ParseName($item.Name)
			$shellItem.InvokeVerb("delete")
			
			if ($PassThru -and !(Test-Path $fullpath)) {
				$item
			}
		}
	}
	end {
	}
}

Export-ModuleMember -Function *
