#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.Document.ps1
#requires -version 5

<#
.SYNOPSIS
 The nl.nlsw.Document module supports PowerShell processing of documents.
 
.DESCRIPTION

.LINK
 New-XmlDocument
 
.NOTES
 @date 2019-10-26
 @author Ernst van der Pols
 @language PowerShell 5
#>
function Get-HelpOnModuleDocument {
	# since PowerShell does not support get-help on a module,
	# we provide an function that carries the help (and runs it)
	get-help Get-HelpOnModuleDocument
}

if (!(test-path "$PSScriptRoot\nl.nlsw.Document.dll")) {
	# compile the C# types to a DLL library
	Add-Type -Path "$PSScriptRoot\nl.nlsw.Document.cs",`
		"$PSScriptRoot\nl.nlsw.Identifiers.cs",`
		"$PSScriptRoot\nl.nlsw.Items.cs" `
		-ReferencedAssemblies "System.Xml.dll" `
		-OutputAssembly "$PSScriptRoot\nl.nlsw.Document.dll" -OutputType Library
}
# import the library
Add-Type -Path "$PSScriptRoot\nl.nlsw.Document.dll"


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
