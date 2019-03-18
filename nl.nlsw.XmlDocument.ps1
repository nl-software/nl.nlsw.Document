#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.XmlDocument.ps1
# @date 2019-03-18
#requires -version 3

<#
.SYNOPSIS
 Create a new XmlDocument for UTF-8 output.
  
.DESCRIPTION
 Creates a new System.Xml.XmlDocument, and adds the XML-declaration 
 specifying UTF-8 encoding.
 
.NOTES
 @date 2018-10-30
 @author Ernst van der Pols
 @language PowerShell 3
#>
function New-XmlDocument {
	[CmdletBinding()]
	[OutputType([System.Xml.XmlDocument])]	# only for documentation
	param()
	process {
		$doc = New-Object System.Xml.XmlDocument
		$doc.appendChild($doc.CreateXmlDeclaration("1.0", "UTF-8", $null)) | out-null
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
 
.PARAMETER Title
 The title of the document

.NOTES
 @date 2019-03-18
 @author Ernst van der Pols
 @language PowerShell 3
#>
function New-HtmlDocument {
	[CmdletBinding()]
	[OutputType([System.Xml.XmlDocument])]	# only for documentation
	param(
		[string]$Title
	)
	process {
		$doc = New-Object System.Xml.XmlDocument
		$doc.appendChild($doc.CreateXmlDeclaration("1.0", "UTF-8", $null)) | out-null
		$html = $doc.appendChild($doc.CreateElement("","html", "http://www.w3.org/1999/xhtml"))
		$head = $html.appendChild($doc.CreateElement("","head", "http://www.w3.org/1999/xhtml"))
		if ($Title) {
			$title = $head.appendChild($doc.CreateElement("","title", "http://www.w3.org/1999/xhtml"))
			$title.InnerText = $Title
		}		
		$body = $html.appendChild($doc.CreateElement("","body", "http://www.w3.org/1999/xhtml"))
		return $doc
	}
}

<#
.SYNOPSIS
 Add a new XmlElement to a specified parent node, optionally with the specified attributes.
 
.DESCRIPTION
 Creates a new System.Xml.XmlElement with the specified Qualified Name,
 appends it to the parent, and sets the attributes.
 
.PARAM parent
 The parent node.
 
.PARAM prefix
 The namespace prefix of the name of the new element.
 
.PARAM localName
 The Local Name of the new element.
 
.PARAM namespace
 The namespace specifier (URI) of the new element
 
.PARAM attributes
 The (optional) attributes of the new element.
 
.EXAMPLE
 Add a new html:img to a html:p, with html as default namespace. Use an ordered hashtable to control the
 order of the attributes in the output.
	$img = Add-XmlElement $p "" "img" "http://www.w3.org/1999/xhtml" ([ordered]@{
		"src"="images/example.jpg";
		"alt"="An example"
	})

#>
function Add-XmlElement {
	[CmdletBinding()]
	[OutputType([System.Xml.XmlElement])]	# only for documentation
	param (
		[Parameter(Mandatory=$True)]
		[System.Xml.XmlNode]$parent,
		[Parameter(Mandatory=$True)]
		[AllowEmptyString()]
		[string]$prefix,
		[Parameter(Mandatory=$True)]
		[string]$localName,
		[Parameter(Mandatory=$True)]
		[string]$namespace,
		[Parameter(Mandatory=$false)]
		[hashtable]$attributes
	)
	process {
		$document = if ($parent -is [System.Xml.XmlDocument]) { $parent } else { $parent.OwnerDocument }
		$child = $parent.AppendChild($document.CreateElement($prefix,$localName,$namespace))
		if ($attributes) { 
			foreach ($attr in $attributes.GetEnumerator()) {
				$child.SetAttribute($attr.Key,$attr.Value) | out-null
			}
		}
		return $child
	}
}

<#
.SYNOPSIS
 Add an XmlText node to the specified parent node.
 
.DESCRIPTION
 Creates a new System.Xml.XmlText with the specified text,
 and appends it to the parent.
 
.PARAM parent
 The parent node.
 
.PARAM text
 The text string.
 
.EXAMPLE
 Add a new html:img to a html:p, with html as default namespace. Use an ordered hashtable to control the
 order of the attributes in the output.
	Add-XmlElement $p "Text to append" | out-null
#>
function Add-XmlText {
	[CmdletBinding()]
	[OutputType([System.Xml.XmlText])]	# only for documentation
	param (
		[Parameter(Mandatory=$True)]
		[System.Xml.XmlNode]$parent,
		[Parameter(Mandatory=$True)]
		[AllowEmptyString()]
		[string]$text
	)
	process {
		$document = if ($parent -is [System.Xml.XmlDocument]) { $parent } else { $parent.OwnerDocument }
		$child = $parent.AppendChild($document.CreateTextNode($text))
		return $child
	}
}

<#
.SYNOPSIS
 Get the body element of the specified html document.

.PARAM document
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

.PARAM document
 The html document.
#>
function Get-HtmlHead {
	[CmdletBinding()]
	[OutputType([System.Xml.XmlElement])]	# only for documentation
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
 Create a new XmlNamespaceManager for the XmlDocument, and register the specified namespaces.
 
.DESCRIPTION
 An XmlNamespaceManager is required when performing XPath-queries with SelectNodes() or SelectSingleNode()
 on an XmlDocument.
 Note: do not forget to specify the default namespace of the document with an explicit prefix for usage
 in these XPath-queries. No prefix means a non-namespace XML-node in this case.

.PARAM xmldoc
 The XmlDocument to associate the namespacemanager with.
 
.PARAM namespaces
 The namespaces to add the the manager.
 
.EXAMPLE
	$sourcensm = New-XmlNamespaceManager $source @{
		"html" = "http://www.w3.org/1999/xhtml";
		"dc" = "http://purl.org/dc/elements/1.1/"
	}
#>
function New-XmlNamespaceManager {
	[CmdletBinding()]
	[OutputType([System.Xml.XmlNamespaceManager])]	# only for documentation
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
		return ,$nsm	# wrap in array to return the complete container
	}
}


Export-ModuleMember -Function *
