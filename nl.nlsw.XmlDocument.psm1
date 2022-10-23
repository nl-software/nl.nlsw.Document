#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.XmlDocument.psm1
# @copyright Ernst van der Pols, Licensed under the EUPL-1.2-or-later
# @date 2021-10-30
#requires -version 5
using namespace System.Xml

<#
.SYNOPSIS
 XmlDocument utility class.

.DESCRIPTION
 Since class support in PowerShell 5.0 is still limited, we use it here
 only for declaration of some static XML related data, with various
 static operations.
#>
class XmlDoc {
	# known media-types to contain an XML document
	static [string[]]$mediaTypes = @(
		"text/xml",
		"application/xml",
		"application/xhtml+xml"
	);
	# known file name extensions
	static [string[]] $extension = @(
		"xml",
		"xhtml"
	);

	static [string] $nsDublinCore = "http://purl.org/dc/elements/1.1/";
	static [string] $nsHtml = "http://www.w3.org/1999/xhtml";
	static [string] $nsOpenDocumentContainer = "urn:oasis:names:tc:opendocument:xmlns:container";
	static [string] $nsvCard40 = "urn:ietf:params:xml:ns:vcard-4.0";
	static [string] $nsXlink = "http://www.w3.org/1999/xlink";
	static [string] $nsXsi = "http://www.w3.org/2001/XMLSchema-instance";

	# namespace prefixes with the corresponding namespace URI
	static [hashtable] $namespaces = @{
		"html" = [XmlDoc]::nsHtml;
		"dc" = [XmlDoc]::nsDublinCore;
		"odc" = [XmlDoc]::nsOpenDocumentContainer;
		"xcard" = [XmlDoc]::nsvCard40;
		"xlink" = [XmlDoc]::nsXlink;
		"xsi" = [XmlDoc]::nsXsi;
	};

	# static constructor
	static XmlDoc() {
	}

	# check if the specified media type is a valid XML MIME type
	static [bool] IsValidMediaType([string]$mediaType) {
		return [XmlDoc]::mediaTypes.contains($mediaType);
	}

	# Set the attributes of the specified element
	# @note existing attributes are not cleared, but may be overwritten
	# @param $attributes a hashtable or [ordered] hashtable with the attributes
	static [void] SetAttributes([System.Xml.XmlElement]$element, [System.Collections.IDictionary]$attributes) {
		if ($attributes) {
			foreach ($attr in $attributes.GetEnumerator()) {
				if ($attr.Key.Contains(':')) {
					$prefix,$localName = ($attr.Key -split ':')
					if ($prefix.StartsWith("xml")) {
						# xml: and xmlns: simply pass on
						$element.SetAttribute($attr.Key,$attr.Value)
					}
					else {
						# is it a known prefix
						$ns = [XmlDoc]::namespaces[$prefix]
						if (!$ns) {
							# lookup namespaceURI in the document based on the prefix
							$node = $element
							$nsdecl = "xmlns:" + $prefix
							while ($node -and !$ns) {
								$ns = $node.GetAttribute($nsdecl)
								$node = $node.ParentNode
							}
						}
						$element.SetAttribute($localName, $ns, $attr.Value)
					}
				}
				else {
					$element.SetAttribute($attr.Key,$attr.Value)
				}
			}
		}
	}

}

<#
.SYNOPSIS
 Create a new XmlDocument for UTF-8 output.

.DESCRIPTION
 Creates a new System.Xml.XmlDocument, and adds the XML-declaration
 specifying UTF-8 encoding.

.NOTES
 @date 2018-10-30
 @author Ernst van der Pols
#>
function New-XmlDocument {
	[CmdletBinding()]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification="ConfirmImpact=None")]
	[OutputType([System.Xml.XmlDocument])]
	param()
	process {
		$doc = New-Object System.Xml.XmlDocument
		$doc.AppendChild($doc.CreateXmlDeclaration("1.0", "UTF-8", $null)) | out-null
		return $doc
	}
}

<#
.SYNOPSIS
 Create a new XmlDocument for UTF-8 output with HTML content.

.DESCRIPTION
 Creates a new System.Xml.XmlDocument, and adds the XML-declaration
 specifying UTF-8 encoding.
 In addition the html document node and head and body child elements
 are added. The title element is set in the header.

.PARAMETER title
 The title of the document

.OUTPUTS
 System.Xml.XmlDocument

.NOTES
 @date 2019-03-18
 @author Ernst van der Pols
 @language PowerShell 3
#>
function New-HtmlDocument {
	[CmdletBinding()]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification="ConfirmImpact=None")]
	[OutputType([System.Xml.XmlDocument])]
	param(
		[string]$title
	)
	process {
		$doc = New-XmlDocument
		$html = $doc | Add-HtmlElement "html"
		$head = $html | Add-HtmlElement "head"
		if ($title) {
			$head | Add-HtmlElement "title" $null $title | out-null
		}
		$html | Add-HtmlElement "body" | out-null
		return $doc
	}
}

<#
.SYNOPSIS
 Add a new XmlElement of the HTML language to a specified parent node,
 optionally with the specified attributes.

.DESCRIPTION
 Creates a new System.Xml.XmlElement with the specified LocalName of the
 HTML namespace, appends it to the parent, and sets the attributes.

.PARAMETER parent
 The parent node.

.PARAMETER localName
 The Local Name of the new element.

.PARAMETER attributes
 The (optional) attributes of the new element.

.PARAMETER text
 The (optional) text content of the new element.

.EXAMPLE
	$img = $p | Add-HtmlElement "img" ([ordered]@{
		"src"="images/example.jpg";
		"alt"="An example"
	})

 Add a new html:img to a html:p, with html as default namespace. Use an ordered hashtable to control the
 order of the attributes in the output.
#>
function Add-HtmlElement {
	[CmdletBinding(DefaultParameterSetName="Pipe")]
	[OutputType([System.Xml.XmlElement])]	# only for documentation
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="Pipe")]
		#[Parameter(Mandatory=$true, Position=0, ParameterSetName="Pos")]
		[System.Xml.XmlNode]$parent,

		[Parameter(Mandatory=$true, Position=0, ParameterSetName="Pipe")]
		#[Parameter(Mandatory=$true, Position=1, ParameterSetName="Pos")]
		[string]$localName,

		[Parameter(Mandatory=$false, Position=1, ParameterSetName="Pipe")]
		#[Parameter(Mandatory=$false, Position=2, ParameterSetName="Pos")]
		[System.Collections.IDictionary]$attributes = $null,

		[Parameter(Mandatory=$false, Position=2, ParameterSetName="Pipe")]
		#[Parameter(Mandatory=$false, Position=3, ParameterSetName="Pos")]
		[string]$text = $null
	)
	process {
		return $parent | Add-XmlElement "" $localName ([XmlDoc]::nsHtml) $attributes $text
	}
}

<#
.SYNOPSIS
 Add a Processing Instruction node to the specified parent node.

.DESCRIPTION
 Creates a new System.Xml.XmlProcessingInstruction with data for the specified target,
 and appends it to the parent.

.PARAMETER parent
 The parent node.

.PARAMETER target
 The name of the processing instruction.

.PARAMETER data
 The data for the processing instruction.

.INPUTS
 System.Xml.Xml The parent node

.OUTPUTS
 System.Xml.XmlProcessingInstruction

.EXAMPLE
	$document | Add-XmlProcessingInstruction "xml-stylesheet" "href=`"../xsl/to-html.xsl`" type=`"text/xsl`"' | out-null
#>
function Add-XmlProcessingInstruction {
	[CmdletBinding(DefaultParameterSetName="Pipe")]
	[OutputType([System.Xml.XmlProcessingInstruction])]
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="Pipe")]
		[Parameter(Mandatory=$true, Position=0, ParameterSetName="Pos")]
		[System.Xml.XmlNode]$parent,

		[Parameter(Mandatory=$true, Position=0, ParameterSetName="Pipe")]
		[Parameter(Mandatory=$true, Position=1, ParameterSetName="Pos")]
		[string]$target,

		[Parameter(Mandatory=$true, Position=1, ParameterSetName="Pipe")]
		[Parameter(Mandatory=$true, Position=2, ParameterSetName="Pos")]
		[string]$data
	)
	process {
		$document = if ($parent -is [System.Xml.XmlDocument]) { $parent } else { $parent.OwnerDocument }
		$child = $parent.AppendChild($document.CreateProcessingInstruction($target,$data))
		return ($child -as [System.Xml.XmlProcessingInstruction])
	}
}

<#
.SYNOPSIS
 Add a new XmlElement to a specified parent node, optionally with the specified attributes.

.DESCRIPTION
 Creates a new System.Xml.XmlElement with the specified Qualified Name,
 appends it to the parent, and sets the attributes.

.PARAMETER parent
 The parent node.

.PARAMETER prefix
 The namespace prefix of the name of the new element.

.PARAMETER localName
 The Local Name of the new element.

.PARAMETER namespace
 The namespace specifier (URI) of the new element

.PARAMETER attributes
 The (optional) attributes of the new element.

.PARAMETER text
 The (optional) text content of the new element.

.OUTPUTS
 System.Xml.XmlElement

.EXAMPLE
	$img = $p | Add-XmlElement "" "img" "http://www.w3.org/1999/xhtml" ([ordered]@{
		"src"="images/example.jpg";
		"alt"="An example"
	})

 Add a new html:img to a html:p, with html as default namespace. Use an ordered hashtable to control the
 order of the attributes in the output.

#>
function Add-XmlElement {
	[CmdletBinding(DefaultParameterSetName="Pipe")]
	[OutputType([System.Xml.XmlElement])]
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="Pipe")]
		[Parameter(Mandatory=$true, Position=0, ParameterSetName="Pos")]
		[System.Xml.XmlNode]$parent,

		[Parameter(Mandatory=$true, Position=0, ParameterSetName="Pipe")]
		[Parameter(Mandatory=$true, Position=1, ParameterSetName="Pos")]
		[AllowEmptyString()]
		[string]$prefix,

		[Parameter(Mandatory=$true, Position=1, ParameterSetName="Pipe")]
		[Parameter(Mandatory=$true, Position=2, ParameterSetName="Pos")]
		[string]$localName,

		[Parameter(Mandatory=$true, Position=2, ParameterSetName="Pipe")]
		[Parameter(Mandatory=$true, Position=3, ParameterSetName="Pos")]
		[AllowEmptyString()]
		[string]$namespace,

		[Parameter(Mandatory=$false, Position=3, ParameterSetName="Pipe")]
		[Parameter(Mandatory=$false, Position=4, ParameterSetName="Pos")]
		[System.Collections.IDictionary]$attributes = $null,

		[Parameter(Mandatory=$false, Position=4, ParameterSetName="Pipe")]
		[Parameter(Mandatory=$false, Position=5, ParameterSetName="Pos")]
		[string]$text = $null
	)
	process {
		$document = if ($parent -is [System.Xml.XmlDocument]) { $parent } else { $parent.OwnerDocument }
		$child = if ([string]::IsNullOrEmpty($namespace)) {
			$document.CreateElement($localName)
		}
		else {
			$document.CreateElement($prefix,$localName,$namespace)
		}
		$child = $parent.AppendChild($child)
		[XmlDoc]::SetAttributes($child,$attributes)
		if ($text) {
			$child.InnerText = $text
		}
		return ($child -as [System.Xml.XmlElement])
	}
}

<#
.SYNOPSIS
 Add an XmlText node to the specified parent node.

.DESCRIPTION
 Creates a new System.Xml.XmlText with the specified text,
 and appends it to the parent.

.PARAMETER parent
 The parent node.

.PARAMETER text
 The text string.

.OUTPUTS
 System.Xml.XmlText

.EXAMPLE
 Add a new html:img to a html:p, with html as default namespace. Use an ordered hashtable to control the
 order of the attributes in the output.
	Add-XmlElement $p "Text to append" | out-null
#>
function Add-XmlText {
	[CmdletBinding(DefaultParameterSetName="Pipe")]
	[OutputType([System.Xml.XmlText])]
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true, ParameterSetName="Pipe")]
		[Parameter(Mandatory=$true, Position=0, ParameterSetName="Pos")]
		[System.Xml.XmlNode]$parent,

		[Parameter(Mandatory=$true, Position=0, ParameterSetName="Pipe")]
		[Parameter(Mandatory=$true, Position=1, ParameterSetName="Pos")]
		[AllowEmptyString()]
		[string]$text
	)
	process {
		$document = if ($parent -is [System.Xml.XmlDocument]) { $parent } else { $parent.OwnerDocument }
		$child = $parent.AppendChild($document.CreateTextNode($text))
		return ($child -as [System.Xml.XmlText])
	}
}

<#
.SYNOPSIS
 Get the body element of the specified html document.

.PARAMETER document
 The html document.
#>
function Get-HtmlBody {
	[CmdletBinding()]
	[OutputType([System.Xml.XmlElement])]	# only for documentation
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[System.Xml.XmlDocument]$document
	)
	process {
		return $document.DocumentElement.GetElementsByTagName("body")[0]
	}
}

<#
.SYNOPSIS
 Get the head element of the specified html document.

.PARAMETER document
 The html document.
#>
function Get-HtmlHead {
	[CmdletBinding()]
	[OutputType([System.Xml.XmlElement])]
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[System.Xml.XmlDocument]$document
	)
	process {
		return $document.DocumentElement.GetElementsByTagName("head")[0]
	}
}

<#
.SYNOPSIS
 Get a hashtable with a list of well-known XML namespaces and prefixes.
#>
function Get-XmlNamespace {
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param (
	)
	process {
		return [XmlDoc]::namespaces;
	}
}

<#
.SYNOPSIS
 Create a new XmlNamespaceManager for the XmlDocument, and register the specified namespaces.

.DESCRIPTION
 An XmlNamespaceManager is required when performing XPath-queries with SelectNodes()
 or SelectSingleNode() on an XmlDocument.

 Note: do not forget to specify the default namespace of the document with an explicit prefix for usage
 in these XPath-queries. No prefix means a non-namespace XML-node in this case.

.PARAMETER xmldoc
 The XmlDocument to associate the namespacemanager with.

.PARAMETER namespaces
 The namespaces to add to the manager.

.OUTPUTS
 System.Xml.XmlNamespaceManager

.NOTES
 The single XmlNamespaceManager is returned in an array wrapper to compensate
 PowerShell's container enumeration feature.

.EXAMPLE
	$sourcensm = New-XmlNamespaceManager $source @{
		"html" = "http://www.w3.org/1999/xhtml";
		"dc" = "http://purl.org/dc/elements/1.1/"
	}
#>
function New-XmlNamespaceManager {
	[CmdletBinding()]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification="ConfirmImpact=None")]
	[OutputType([System.Xml.XmlNamespaceManager])]
	param (
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[System.Xml.XmlDocument]$xmldoc,

		[Parameter(Mandatory=$false)]
		[hashtable]$namespaces
	)
	process {
		[System.Xml.XmlNamespaceManager]$nsm = New-Object System.Xml.XmlNamespaceManager($xmldoc.NameTable)
		if ($namespaces) {
			foreach ($ns in $namespaces.GetEnumerator()) {
				$nsm.AddNamespace($ns.Key, $ns.Value)
			}
		}
		Write-Output $nsm -NoEnumerate
	}
}


Export-ModuleMember -Function *
