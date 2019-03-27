#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.Document.ps1
# @date 2019-03-19
#requires -version 5

<#
.SYNOPSIS
 The nl.nlsw.Document module supports PowerShell processing of documents.
 
.DESCRIPTION

.LINK
 New-XmlDocument
 
.NOTES
 @date 2019-03-18
 @author Ernst van der Pols
 @language PowerShell 5
#>
function Get-HelpOnModuleDocument {
	# since PowerShell does not support get-help on a module,
	# we provide an function that carries the help (and runs it)
	get-help Get-HelpOnModuleDocument
}

# compile the C# types to a library in the TEMP folder
Add-Type -Path "$PSScriptRoot\nl.nlsw.Identifiers.cs", `
	"$PSScriptRoot\nl.nlsw.Items.cs" `
	-ReferencedAssemblies "System.Xml.dll" `
	-OutputAssembly "$env:TEMP\nl.nlsw.Document.dll" -OutputType Library
# import the library
Add-Type -Path "$env:TEMP\nl.nlsw.Document.dll"


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
 Gets the MIME (content or media) type from the Windows Registry for the specified file name.

.DESCRIPTION
 The file name extension is used to lookup the corresponding MIME-type in the registry.

.PARAMETER fileName
 The name of the file to get the MIME type for. It must contain at least an extension.

.PARAMETER defaultMimeType
 The default MIME type, if no matching value can be found. By default 'application/octet-stream'
 is returned, indicating a binary file.
#>
function Get-MimeType {
	param (
		[string]$fileName,
		[string]$defaultMimeType = "application/octet-stream"
	)
	# lookup media type in registry by file name extension
	$mimeType = $defaultMimeType;
	$ext = [System.IO.Path]::GetExtension($fileName).ToLower();
	[Microsoft.Win32.RegistryKey]$regKey = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey($ext);
	if ($regKey -and $regKey.GetValue("Content Type")) {
		$mimeType = $regKey.GetValue("Content Type").ToString();
	}
	return $mimeType;
}

<#
.SYNOPSIS
 Get a file name extension for the specified MIME (content or media) type.
 
.DESCRIPTION
 The MIME type is 'decoded' to create a file extension from.
 
 @note This function only works for specific use-cases!
 @todo Expand the usability, e.g. a reverse lookup in the registry

.PARAMETER mimeType
 The MIME type to get a file name extension for.
#>
function Get-ExtensionFromMimeType {
	param ([string] $mimeType)
	# convert some media types into a file name extension
	if ($mimeType -match "^(?<type>[^/]+)/(?<subtype>.*)") {
		switch ($matches['type']) {
		'image' {
				return $matches['subtype']
				break
			}
		}
	}
	return $null
}

Export-ModuleMember -Function *
