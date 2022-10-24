#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.Document.psm1
# @copyright Ernst van der Pols, Licensed under the EUPL-1.2-or-later
#requires -version 5

# Import the nl.nlsw.Document, nl.nlsw.identifiers, and nl.nlsw.Items .NET classes.
#
$assembly = "$PSScriptRoot/lib/netstandard2.0/nl.nlsw.Document.dll"
if ((test-path $assembly)) {
	# import the library
	Add-Type -Path $assembly
}
else {
	# create the assembly from source
	$assembly = "$PSScriptRoot/nl.nlsw.Document.dll"
	if (!(test-path $assembly)) {
		# compile the C# types to a DLL library
		Add-Type -Path "$PSScriptRoot/source/nl.nlsw.Document.cs",`
			"$PSScriptRoot/source/nl.nlsw.Identifiers.cs",`
			"$PSScriptRoot/source/nl.nlsw.Items.cs" `
			-ReferencedAssemblies "System.Xml.dll" `
			-OutputAssembly $assembly -OutputType Library
	}
	# import the library
	Add-Type -Path $assembly
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
