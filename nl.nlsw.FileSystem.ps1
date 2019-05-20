#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.FileSystem.ps1
# @date 2019-05-17
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
 Remove a file system item to the recycle bin, with or without confirmation dialog.

.DESCRIPTION
 Replacement of Remove-Item in case you want a file or folder to be moved to the
 recycle bin. This function uses the VisualBasic operations of .NET for the implementation.

.PARAMETER Path
 The path name or the FileSystemInfo object of the item to remove.
 
.PARAMETER Confirm
 Shows a confirmation dialog for the user to confirm the operation. If the user
 cancels the operation, an exception is thrown.

.PARAMETER WhatIf
 Writes a message to the host indicating the operation that will be performed by this function.
 
.LINK
 https://stackoverflow.com/questions/502002/how-do-i-move-a-file-to-the-recycle-bin-using-powershell

.NOTES
 There is a Recycle PS module.
#>
function Remove-ItemToRecycleBin {
	[CmdletBinding()]
	param ( 
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[object]$Path,
		
		[switch]$Confirm,
		[switch]$WhatIf
	)
    $item = Get-Item -Path $Path -ErrorAction SilentlyContinue
    if ($item -eq $null) {
        Write-Error("'{0}' not found" -f $Path)
    }
    else {
        $fullpath=$item.FullName
		if ($WhatIf) {
			write-host "What if: Performing the operation `"Remove-ItemToRecycleBin`" on target `"$fullpath`""
		}
		else {
			Add-Type -AssemblyName Microsoft.VisualBasic

			$uioption = if ($Confirm) { "AllDialogs" } else { "OnlyErrorDialogs" }
			Write-Verbose ("Moving '{0}' to the Recycle Bin" -f $fullpath)
			if (Test-Path -Path $fullpath -PathType Container) {
				[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($fullpath,$uioption,'SendToRecycleBin','ThrowException')
			}
			else {
				[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($fullpath,$uioption,'SendToRecycleBin','ThrowException')
			}
		}
    }
}

Export-ModuleMember -Function *
