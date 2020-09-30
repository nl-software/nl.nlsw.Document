#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.EPUB.psm1
# @date 2020-09-30
#requires -version 5

<#
.SYNOPSIS
 Convert an XHTML file to an EPUB 3.1 file.
  
.DESCRIPTION
 Convert an XHTML webpage to an EPUB3 file, suited for e-Readers.
 
.PARAMETER inputObject
 The (name of the) file to convert.

.PARAMETER Ext
 The name of the extension of the output file(s).
 
.NOTES
 @date 2018-10-30
 @author Ernst van der Pols
 @language PowerShell 5
#>
function ConvertTo-EPUB {
	[CmdletBinding()]
	param ( 
		[Parameter(Mandatory=$True, ValueFromPipeline = $True, ValueFromPipelinebyPropertyName = $True, HelpMessage="Enter the name of the file to process")]
		[object]$inputObject = $(throw "FileName is required."),
		
		[Parameter(Mandatory=$False)]
		[string]$Ext = "epub"
	)

	begin {
		# .NET 4.5 required for using ZipFile and friends
		Add-Type -assembly "System.IO.Compression"
		Add-Type -assembly "System.IO.Compression.FileSystem"
		
		#$ZipFile = [System.IO.Compression.ZipFile]::Open("elb.epub.zip", "Read")
		#$ZipFile.Entries
		
		<#
		.SYNOPSIS
		 Get the title of the specified html:section.
		 Might be a descendant h1..h4, or @title
		#>
		function Get-SectionTitle {
			param (
				[Parameter(Mandatory=$True)]
				[System.Xml.XmlNode]$section,

				[Parameter(Mandatory=$True)]
				[System.Xml.XmlNamespaceManager]$namespaceManager
			)
			if ($section.HasAttribute("title")) {
				return $section.GetAttribute("title")
			}
			$titlenode = $section.SelectSingleNode("@title|.//html:h1|.//html:h2|.//html:h3|.//html:h4",$namespaceManager)
			if (($titlenode -eq $null) -or ($titlenode.InnerText -eq "")) {
				return $section.GetAttribute("id")
			}
			return $titlenode.InnerText
		}

		$ns = @{
			"html" = "http://www.w3.org/1999/xhtml";
			"epub" = "http://www.idpf.org/2007/ops";
			"opf" = "http://www.idpf.org/2007/opf";
			"dc" = "http://purl.org/dc/elements/1.1/";
			"odc" = "urn:oasis:names:tc:opendocument:xmlns:container";
			"rendition" = "http://www.idpf.org/vocab/rendition/#"
		}

		$epub = @{
			"version" = "3.1"; "xml:lang" = "nl";
			"media-types" = @(
				"application/xhtml+xml", "application/javascript", "application/x-dtbncx+xml",
				"application/font-sfnt", "application/font-woff", "application/smil+xml", "application/pls+xml",
				"audio/mpeg", "audio/mp4", "text/css", "font/woff2",
				"image/gif", "image/jpeg", "image/png", "image/svg+xml"
			)
		}

		<#
		.SYNOPSIS
		 Register an OPF (zip) archive entry in the OPF manifest.
		#>
		function Add-ToManifest {
			param (
				[Parameter(Mandatory=$True)]
				[System.Xml.XmlNode]$manifest,

				[Parameter(Mandatory=$True)]
				[System.IO.Compression.ZipArchiveEntry]$entry,
				
				[Parameter(Mandatory=$false)]
				[string]$mediatype,

				[Parameter(Mandatory=$false)]
				[string]$id
			)
			if ($mediatype -eq "") {
				$mediatype = Get-MimeType $entry.FullName
			}
			# create a unique id for the item
			if ($id -eq "") {
				$id = "E{0:d4}" -f ($manifest.ChildNodes.Count + 1)
			}
			else {
				$id = "E{0:d4}-{1}" -f ($manifest.ChildNodes.Count + 1),$id
			}
			$mitem = Add-XmlElement $manifest "" "item" $ns["opf"] ([ordered]@{
				"id"=$id;
				"href"=$entry.FullName;
				"media-type"=$mediatype
			})
			Write-Action "added" $entry.FullName
			return $mitem
		}
		<#
		.SYNOPSIS
		 Add a reference to a manifest item to the spine.
		#>
		function Add-ToSpine {
			param (
				[Parameter(Mandatory=$True)]
				[System.Xml.XmlNode]$spine,

				[Parameter(Mandatory=$True)]
				[System.Xml.XmlNode]$mitem
			)
			# add to spine
			$sitemref = Add-XmlElement $spine "" "itemref" $ns["opf"] ([ordered]@{
				"idref" = $mitem.GetAttribute("id");
				#"linear" = "yes"
			})
			return $sitemref
		}
		<#
		.SYNOPSIS
		 Scan one or more XHTML node elements for relative referenced resources, and add those resources 
		 to the OPF archive, and register it in the OPF manifest.
		#>
		function Add-ReferencedResource {
			param (
				[Parameter(Mandatory=$True)]
				[System.IO.Compression.ZipArchive]$archive,
				
				[Parameter(Mandatory=$True)]
				[System.Xml.XmlNode]$manifest,

				[Parameter(Mandatory=$True)]
				[string]$baseFolder,

				[Parameter(Mandatory=$True, ValueFromPipeline = $True)]
				[object]$nodes,		# System.Xml.XmlNodeList or System.Xml.XmlNode
			
				[Parameter(Mandatory=$True)]
				[System.Xml.XmlNamespaceManager]$namespaceManager
			)
			# attributes that may contain a references resource URI, per html element
			$htmlUris = @{
				a="href"; applet="codebase"; area="href"; base="href"; blockquote="cite"; 
				body="background"; del="cite"; form="action"; head="profile";
				iframe="longdesc src"; img="longdesc src usemap srcset"; input="src usemap formaction"; ins="cite";
				link="href"; object="classid codebase data usemap archive"; q="cite"; script="src";
				audio="src"; button="formaction"; command="icon"; embed="src"; html="manifest";
				source="src srcset"; track="src"; video="poster src";
				# @todo meta[refresh].content, svg.image.href
				# @todo css url()
			}
			foreach ($node in $nodes) {
				$uriAttrs = $htmlUris[$node.LocalName]
				if ($uriAttrs -eq $null) { continue }
				foreach ($attr in $uriAttrs.Split()) {
					foreach ($href in $node.GetAttribute($attr).Split()) {
						if ($href -ne "") {
							try {
								$uri = new-object System.Uri($href,[System.UriKind]::RelativeOrAbsolute)
								if (!$uri.IsAbsoluteUri) {
									$filename = Join-Path $baseFolder $uri
									$mediatype = Get-MimeType($filename)
									if ((test-path $filename) -and ($mediatype -in $epub["media-types"])) {
										$entry = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$filename,$href)
										$mitem = Add-ToManifest $manifest $entry -mediatype $mediatype
										# add additional manifest properties
										if ($mediatype.StartsWith("image") -and ($node.SelectSingleNode("ancestor::html:section[contains(concat(' ',normalize-space(@epub:type),' '),' cover ')]",$namespaceManager) -ne $null)) {
											$mitem.SetAttribute("properties", "cover-image")
										}
									}
									else {
										write-warning "referenced file ""$filename"" not found or invalid media-type"
									}
								}
							}
							catch [System.Exception] {
								write-error "exception while processing resource $($href): $($_.Message)"
								continue
							}
						}
					}
				}
			}
		}

		Write-Verbose "[$($MyInvocation.MyCommand.CommandType): $($MyInvocation.MyCommand.Name)] begin $Action $Path > $Path.$Ext."
		# count files processed.
		$FileCount = 0
	}

	process {
		$item = Get-Item $inputObject -ErrorAction "Stop"
		$type = Get-MimeType($item.FullName)
		if ($type -ne "application/xhtml+xml") {
			write-error """$($item.Name)"" has an invalid media type: $type "
			continue
		}
		Write-Action "reading" $item.FullName
		try {
			[System.Xml.XmlDocument]$source = New-Object System.Xml.XmlDocument
			# keep whitespace
			$source.PreserveWhitespace = $true
			$source.Load($item.FullName)
			$sourcensm = New-XmlNamespaceManager $source @{
				"html" = $ns["html"]; # for XPath referencing
				"epub" = $ns["epub"]
			}
		}
		catch [System.Exception] {
			Write-Error "Couldn't read $($item.Name) : $_.Message"
			continue
		}

		# determine the (absolute) output file name
		$outFileName = [System.IO.Path]::ChangeExtension($item.FullName,$Ext)
		$i=0; while (test-path -pathType Leaf $outFileName) {
			$base = [System.IO.Path]::GetDirectoryName($item.FullName)
			$filename = [System.IO.Path]::GetFileNameWithoutExtension($item.FullName)
			$filename = "{0}({1}).{2}" -f $filename,++$i,$Ext
			$outFileName = [System.IO.Path]::Combine($base,$filename)
		}
		# @note use an absolute path for creating files via .NET processes
		#$outFileName = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outFileName)
		Write-Action "creating" $outFileName

		try {
			# create the output zipstream
			$outStream = New-Object System.IO.FileStream $outFileName, ([IO.FileMode]::Create), ([IO.FileAccess]::ReadWrite), ([IO.FileShare]::None)
			$zipStream = New-Object System.IO.Compression.ZipArchive $outStream, ([System.IO.Compression.ZipArchiveMode]::Update)

			# add the mimetype file
			[System.IO.Compression.ZipArchiveEntry]$mimetypeEntry = $zipStream.CreateEntry("mimetype")
			$writer = new-object System.IO.StreamWriter($mimetypeEntry.Open())
			$writer.Write("application/epub+zip")
			$writer.Close()
			Write-Action "added" $mimetypeEntry.FullName

			# add the META-INF folder
			$zipStream.CreateEntry("META-INF/") | out-null

			# create and add the META-INF/container.xml
			[System.IO.Compression.ZipArchiveEntry]$containerEntry = $zipStream.CreateEntry("META-INF/container.xml")
			#<?xml version="1.0"?>
			#<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
			#  <rootfiles>
			#    <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
			#  </rootfiles>
			#</container>
			#[System.Xml.XmlDocument]
			$odc = New-XmlDocument
			$nsm = New-XmlNamespaceManager $odc @{ "" = $ns["odc"] }
			$odContainer = Add-XmlElement $odc "" "container" $ns["odc"] @{ "version"="1.0" }
			$rootFiles = Add-XmlElement $odContainer "" "rootfiles" $ns["odc"]
			$rootFile = Add-XmlElement $rootFiles "" "rootfile" $ns["odc"] ([ordered]@{
				"full-path"="content.opf";
				"media-type" = "application/oebps-package+xml";
			})
			$odc.Save($containerEntry.Open())
			Write-Action "added" $containerEntry.FullName

			# create and add the EPUB package description (content.opf)
			[System.IO.Compression.ZipArchiveEntry]$contentEntry = $zipStream.CreateEntry("content.opf")
			Write-Action "creating" $contentEntry.Name
			$opf = New-XmlDocument
			$nsm = New-XmlNamespaceManager $opf @{ "" = $ns["opf"]; "dc" = $ns["dc"] }
			$package = Add-XmlElement $opf "" "package" $ns["opf"] ([ordered]@{
				"version"=$epub["version"];
				"xml:lang"=$epub["xml:lang"]
			})
			# create the required child nodes that hold the package data
			$metadata = Add-XmlElement $package "" "metadata" $ns["opf"] ([ordered]@{
				# define the Dublin Core namespace
				"xmlns:dc"=$ns["dc"];
				# define the OPF namespace for additional attributes
				"xmlns:opf"=$ns["opf"]
			})
			$manifest = Add-XmlElement $package "" "manifest"  $ns["opf"]
			$spine = Add-XmlElement $package "" "spine" $ns["opf"]

			Write-Action "collecting" "metadata and manifest entries"
			# set the dc:title
			$(Add-XmlElement $metadata "dc" "title" $ns["dc"]).InnerText = $source.html.head.title
			Write-Action "dc:title" $source.html.head.title
			
			$headlinks = new-object -type System.Collections.ArrayList

			# copy additional meta data, like dc:creator
			foreach ($node in $source.html.head.ChildNodes) {
				# Write-Action "node" ($node.Name + " - " + $node.NamespaceURI)
				switch ($node.NamespaceURI) {
				$ns["dc"] {	# a Dublin Core element is copied
						$newnode = $opf.ImportNode($node,$true)
						$newnode.Prefix = "dc"
						switch ($newnode.LocalName) {
							"identifier" {
									if ($package.GetAttribute("unique-identifier") -eq "") {
										if ([string]::IsNullOrEmpty($newnode.GetAttribute("id"))) {
											$newnode.SetAttribute("id","epubid") | out-null
										}
										$package.SetAttribute("unique-identifier",$newnode.GetAttribute("id")) | out-null
									}
									break
								}
						}
						$metadata.AppendChild($newnode) | out-null
						Write-Action $newnode.Name $newnode.InnerText
						break
					}
				$ns["opf"] {	# an Open Package Format (EPUB) meta element is copied, merging into the default namespace
						$newnode = $opf.ImportNode($node,$true)
						$newnode.Prefix = ""
						$metadata.AppendChild($newnode) | out-null
						Write-Action $newnode.Name $newnode.InnerText
						break
					}
				$ns["html"] {
						switch ($node.LocalName) {
						"style" {
								if ($node.GetAttribute("href") -ne "") {
									Add-ReferencedResource $zipStream $manifest $item.Directory $node $sourcensm
									$headlinks.Add($node) | out-null
								}
								elseif ($node.GetAttribute("type") -eq "text/css") {
									# store the style to a file in the css folder
									$cssdata = if ($node."#cdata-section") { $node."#cdata-section" } else { $node.InnerText }
									# create a unique name for the file
									$cssname = "css/{0}-{1:d4}.css" -f $item.BaseName,$manifest.ChildNodes.Count
									# create a css file with data taken from the source
									[System.IO.Compression.ZipArchiveEntry]$styleEntry = $zipStream.CreateEntry($cssname)
									$writer = new-object System.IO.StreamWriter($styleEntry.Open())
									$writer.Write($cssdata)
									$writer.Close()
									$stylecss = Add-ToManifest $manifest $styleEntry

									$link = $node.OwnerDocument.CreateElement("","link", $ns["html"])
									$link.SetAttribute("rel", "stylesheet") | out-null
									$link.SetAttribute("type", "text/css") | out-null
									$link.SetAttribute("href", $cssname) | out-null
									$headlinks.Add($link) | out-null
								}
								break
							}
						"link" {
								Add-ReferencedResource $zipStream $manifest $item.Directory $node $sourcensm
								$headlinks.Add($node) | out-null
								break
							}
						}
						break
					}
				}
				# @todo check / update <meta property="dcterms:modified">....</meta>
			}

			# look for local external files referenced from the source to include in the EPUB package
			$links = $source.html.body.SelectNodes(".//html:img", $sourcensm)
			Add-ReferencedResource $zipStream $manifest $item.Directory $links $sourcensm

			# sectionize the document: create a file per section
			# a section may be a section container, in which case only header and footer are written and a reference list to the contained sections
			$sections = $source.html.body.SelectNodes(".//html:section[@id]", $sourcensm)
			foreach ($section in $sections) {
				# convert into a separate file
				$id = $section.GetAttribute("id")
				if ($id -eq "") {
					write-warning ("section without id attribute")
					continue
				}
				$sectionId = "{0}-{1}" -f $item.BaseName,$id
				$sectionFileName = "{0}.xhtml" -f $sectionId
				$sectionEntry = $zipStream.CreateEntry($sectionFileName)
				
				[System.Xml.XmlDocument]$sxml = New-XmlDocument
				# do not auto indent the output
				$sxml.PreserveWhitespace = $true
				$snsm = New-XmlNamespaceManager $sxml @{ ""=$ns["html"]; "epub"=$ns["epub"] }
				
				$html = Add-XmlElement $sxml "" "html" $ns["html"] @{ "xmlns:epub"=$ns["epub"] }
				$head = Add-XmlElement $html "" "head" $ns["html"]
				$meta = Add-XmlElement $head "" "meta" $ns["html"] ([ordered]@{ "http-equiv"="Content-Type"; "content"="text/html; charset=utf-8" })
				$title = Add-XmlElement $head "" "title" $ns["html"]
				$title.InnerText = Get-SectionTitle $section $sourcensm
				# include links and style-links in the head
				foreach ($node in $headlinks) {
					$xnode = $sxml.ImportNode($node,$true)
					$head.AppendChild($xnode) | out-null
				}
				$body = Add-XmlElement $html "" "body" $ns["html"]
				
				# determine section type: leaf or container
				$childsections = $section.SelectNodes("./html:section[@id]", $sourcensm)
				if ($childsections.Count -eq 0) {
					$content = $sxml.ImportNode($section,$true)
				}
				else {
					$content = $sxml.ImportNode($section,$false)
					# selectively import content (header and footer) and create a navigation list to the child sections
					if ($section.header) {
						$content.AppendChild($sxml.ImportNode($section.header,$true)) | out-null
					}
					$nav = Add-XmlElement $content "" "nav" $ns["html"]
					$ol = Add-XmlElement $nav "" "ol" $ns["html"]
					foreach ($childsection in $childsections) {
						$childsectionUri = "{0}-{1}.xhtml#{1}" -f $item.BaseName,$childsection.GetAttribute("id")
						$li = Add-XmlElement $ol "" "li" $ns["html"]
						$a = Add-XmlElement $li "" "a" $ns["html"] ([ordered]@{
							"href"=$childsectionUri
						})
						$title = Get-SectionTitle $childsection $sourcensm
						$a.InnerText = $title
					}
					if ($section.footer) {
						$content.AppendChild($sxml.ImportNode($section.footer,$true)) | out-null
					}
				}
				$parent = $section.ParentNode
				while ($parent -ne $source.html.body) {
					# create a shallow copy of any ancestor nodes up to the body
					$wrapper = $sxml.ImportNode($parent,$false)
					$wrapper.AppendChild($content) | out-null
					$content = $wrapper
					$parent = $parent.ParentNode
				}
				
				# adjust internal hyperlinks
				$links = $content.SelectNodes("descendant::html:a[@href]",$sourcensm)
				foreach ($link in $links) {
					#$href = new-object System.Uri($link.GetAttribute("href"),[System.Urikind]::RelativeOrAbsolute)
					if ($link.GetAttribute("href") -match "^#([A-Za-z_].*)") {
						# lookup the id in the source 
						$target = $source.SelectSingleNode(("//html:*[@id='{0}']" -f $matches[1]),$sourcensm)
						if ($target -ne $null) {
							$targetsection = $target.SelectSingleNode("ancestor-or-self::html:section[@id][1]",$sourcensm)
							if ($targetsection -ne $null) {
								$targetsectionUri = "{0}-{1}.xhtml#{2}" -f $item.BaseName,$targetsection.GetAttribute("id"),$matches[1]
								$link.SetAttribute("href",$targetsectionUri)
							}
						}
					}
				}
				
				$body.AppendChild($content) | out-null

				$sxml.Save($sectionEntry.Open())
				
				# add to manifest
				$sitem = Add-ToManifest $manifest $sectionEntry -id $id
				# indicate the (required single) EPUB Navigation Document)
				if ($section.SelectNodes("descendant::html:nav[@epub:type]",$sourcensm) -ne $null) {
					$sitem.SetAttribute("properties","nav")
				}

				# add to spine
				$sitemref = Add-ToSpine $spine $sitem
			}

			# finally save the content.xml
			Write-Action "writing" $contentEntry.Name
			$opf.Save($contentEntry.Open())
		}
		finally {
			$zipStream.Dispose()
			$outStream.Dispose()
		}
		Write-Action "ready" $outFileName
		$FileCount++
	}

	end {
		# If($?){ # only execute if the function was successful.
		Write-Verbose "[$($MyInvocation.MyCommand.Name)] $FileCount files converted."
	}
}
Export-ModuleMember -Function *
