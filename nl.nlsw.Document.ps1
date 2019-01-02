<#
.SYNOPSIS
 Gets the MIME (content or media) type from the Windows Registry for the specified file name.

.DESCRIPTION
 The file name extension is used to lookup the corresponding MIME-type in the registry.
 By default 'application/octet-stream' is returned, indicating a binary file.

.PARAMETER fileName
 The name of the file to get the MIME type for. It must contain at least an extension.
#>
function Get-MimeType {
	param ([string] $fileName)
	# lookup media type in registry by file name extension
	$mimeType = "application/octet-stream";
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
 
.PARAMETER mimeType
 The MIME type to get a file name extension for.

.NOTE
 The cmdlet only works for specific use-cases!
 @todo Expand the usability, e.g. a reverse lookup in the registry
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

#Export-ModuleMember -Function *
