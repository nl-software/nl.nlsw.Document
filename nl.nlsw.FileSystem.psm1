#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.FileSystem.psm1
# @copyright Ernst van der Pols, Licensed under the EUPL-1.2-or-later
# @date 2022-09-08
#requires -version 5

class nlswFilesystem {

	# convert any (range of) invalid path characters to '_'
	static $invalidPathCharRegEx = [regex]"[$([string]([System.IO.Path]::GetInvalidPathChars()))\*\?]+"
	# convert any (range of) invalid filename characters to '_'
	static $invalidFileCharRegEx = [regex]"[$([string]([System.IO.Path]::GetInvalidFileNameChars()))\*\?]+"

	# Replace any (range of) invalid filename characters with an underscore to get a valid filename.
	# @param $filename the filename to validate
	# @return a valid filename
	static [string] GetValidFileName([string]$filename) {
		# convert any (range of) invalid filename characters to '_'
		$leaf = $filename | Split-Path -leaf
		$parent = $filename | Split-Path -parent
		return [System.IO.Path]::Combine([nlswFilesystem]::invalidPathCharRegEx.Replace($parent,"_"),[nlswFilesystem]::invalidFileCharRegEx.Replace($leaf,"_"));
	}

	static [bool] TestFileIsVersioned([string]$filename) {
		# run this test in the CurrentDirectory of the file system
		# @todo check this
		if (Test-Path $filename) {
			# ensure
			# get the svn stat info in verbose xml format
			$fileStat = [xml]$(svn stat --verbose --xml "$filename")
			# test if the file is not under version control
			#write-host $fileStat.status.target.entry."wc-status".item

			if (!$fileStat.status.target.entry -or
				(($fileStat.status.target.entry.path -eq $filename) -and
				 ($fileStat.status.target.entry."wc-status".item -eq "unversioned"))) {
				write-verbose "    unversioned $filename"
				return $false
			}
			write-verbose "      versioned $filename"
			return $true
		}
		# file does not exist
		write-verbose "            new $filename"
		return $false
	}

	static [System.IO.FileInfo] MoveVersionedFile([System.IO.FileInfo]$oldFile, [string]$newFileName) {
		if ($oldFile.Name -ne $newFileName) {
			# get svn status of the old file
			$renamedFile = $null
			if ([nlswFilesystem]::TestFileIsVersioned($oldFile)) {
				write-verbose "  (svn)renaming $($oldFile.Name) > $($newFileName)"
				push-location $oldFile.DirectoryName
				try {
					svn move $oldFile.Name $newFileName
					$renamedFile = get-item $newFileName
				}
				finally {
					pop-location
				}
			}
			else {
				write-verbose "       renaming $($oldFile.Name) > $($newFileName)"
				$renamedFile = Move-Item $oldFile.FullName $newFileName  -passThru #-WhatIf:$WhatIf
			}
			write-verbose "        renamed $renamedFile"
			$oldFile = $renamedFile
		}
		return $oldFile
	}
}

<#
.SYNOPSIS
 Replace any (range of) invalid filename characters with an underscore '_' to get a valid filename.

.DESCRIPTION
 The function replaces any invalid filename character with an underscore.
 The path and filename parts of the input string are handled separately,
 since these have a slightly different set of invalid characters.

 The invalid characters are defined by the System.IO.Path class.

.PARAMETER Path
 The filename to make valid. May be piped.

.INPUT
 System.String

.OUTPUT
 System.String
#>
function Get-ValidFileName {
	[CmdletBinding()]
	[OutputType([System.String])]
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline = $true, ValueFromPipelinebyPropertyName = $true)]
		[string]$Path
	)
	process {
		# convert any (range of) invalid filename characters to '_'
		[nlswFilesystem]::GetValidFileName($Path)
	}
}

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

.PARAMETER AllowClobber
 Do not change the filename with an incremental index "(<n>)" in case the file already exists.
 When using this switch in a typical application, the existing file will be overwritten.

.INPUT
 System.String

.OUTPUT
 System.String
#>
function New-IncrementalFileName {
	[CmdletBinding()]
	[OutputType([System.String])]
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline = $true, ValueFromPipelinebyPropertyName = $true)]
		[string]$Path,

		[Parameter(Mandatory=$false)]
		[switch]$AllowClobber
	)
	begin {
	}
	process {
		# convert any (range of) invalid filename characters to '_'
		# and determine absolute path, to avoid difference between Environment.CurrentDirectory i.s.o. $pwd
		$filepath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($(Get-Location),[nlswFilesystem]::GetValidFileName($Path)))
		# create folder, if non-existing
		$filefolder = [System.IO.Path]::GetDirectoryName($filepath)
		if (!(test-path $filefolder)) {
			new-item -path $filefolder -itemtype Directory | out-null
		}
		# make output file unique with "(n)" extension
		if ((test-path $filepath) -and !$AllowClobber) {
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
	[OutputType([System.IO.FileSystemInfo])]
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

<#
.SYNOPSIS
 Rename or move a file that might be under under version control to another location.

.DESCRIPTION
 A file under version control requires certain operations to be handled via
 the version control interface, e.g. renaming and moving.

 Use this function to rename or move a file that might be under version control.

 Version control systems supported:
 - Subversion

.PARAMETER Path
 The path name of the file to rename or move. Wildcards are permitted.
 Use a dot '.' to specify the current location. The default is the current directory.
 Use the wildcard '*' to specify all items in the current location.

.PARAMETER Destination
 The path to the location where the items are to be moved. By default, the current directory.
 Wildcards are permitted, but the result must specify a single location.
 To rename the item being moved, specify a new name in the value of this parameter.

.PARAMETER PassThru
 Pass the object created through the pipeline.

.INPUTS
 string

.OUTPUTS
 System.IO.FileInfo
#>
function Move-VersionControlledFile {
	[CmdletBinding()]
	[OutputType([System.IO.FileInfo])]
	param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[string]$Path,

        [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[string]$Destination
	)
	begin {
	}
	process {
		$Path | get-item | foreach-object {
			[nlswFilesystem]::MoveVersionedFile($_, $Destination)
		}
	}
	end {
	}
}


<#
.SYNOPSIS
 Test if a file exists and is under version control.

.DESCRIPTION
 A file under version control requires certain operations to be handled via
 the version control interface, e.g. renaming.

 Use this function to test if a file exists and is under version control.

 Version control systems supported:
 - Subversion

.PARAMETER Path
 The path name of the file to test.

.INPUTS
 string

.OUTPUTS
 bool
#>
function Test-VersionControlledFile {
	[CmdletBinding()]
	param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[SupportsWildcards()]
		[ValidateNotNullOrEmpty()]
		[string]$Path
	)
	begin {
	}
	process {
		$Path | get-item | foreach-object { [nlswFilesystem]::TestFileIsVersioned($_) }
	}
	end {
	}
}


Export-ModuleMember -Function *
