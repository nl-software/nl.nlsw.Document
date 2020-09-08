#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.Feed.ps1
# @date 2020-09-08
# @author Ernst van der Pols
#requires -version 5
using namespace System.Xml

<#
.SYNOPSIS
 Read an RSS/Atom Feed
  
.DESCRIPTION
 Read an RSS or Atom web feed from the internet.
 The resulting XML document is returned.
  
.PARAMETER URI
 The URI of the feed.

.INPUTS
 string
 
.OUTPUTS
 System.Xml.XmlDocument

.LINK
 https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest
#>
function Read-Feed {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$false, Position=0, ValueFromPipeline=$true)]
		[string]$URI = "https://podcast.npo.nl/feed/bach-van-de-dag.xml"
	)
	begin {
	}
	process {
		try {
			write-verbose "        GET $URI"
			$request = [System.Net.HttpWebRequest]::Create($URI)
			$request.Method = "GET"
			#$request.ContentType = "application/json"
			$response = $request.GetResponse()
			write-verbose "   response $($response.StatusCode)"
			if ($response.StatusCode -eq [System.Net.HttpStatusCode]::OK) {
				$stream = $response.GetResponseStream()
				$document = [System.Xml.XmlDocument]::new()
				$document.Load($stream);
				$document
			}
			$response.Close()
		}
		catch {
			throw
		}
	}
	end {
	}
}

<#
.SYNOPSIS
 Saves the attachments of an RSS/Atom Feed to a local folder
  
.DESCRIPTION
 Read an RSS or Atom web feed from the internet.
  
.PARAMETER Path
 The local folder to save the attachments in.

.INPUTS
 System.Xml.XmlDocument
 
.OUTPUTS
 System.IO.FileInfo

.LINK
 https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest
#>
function Save-FeedAttachments {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$false, Position=0, ValueFromPipeline=$true)]
		[System.Xml.XmlDocument]$InputObject,
		
		[Parameter(Mandatory=$false, Position=1)]
		[string]$Path
	)
	begin {
		if ($Path) {
			if (!(Test-Path $Path)) {
				New-Item -Path $Path -ItemType "directory"
			}
		}
	}
	process {
		$InputObject | where-object { $_ -is [System.Xml.XmlDocument] } | foreach-object {
			$doc = $InputObject
			# rss/channel/item/link
			# select the items of the (single) channel
			$items = $doc.DocumentElement.SelectNodes("channel/item");
			foreach ($item in $items) {
				$title = $item.SelectSingleNode("title").InnerText;
				write-verbose "       item $title"
				$link = $item.SelectSingleNode("link").InnerText;
				write-verbose "       link $link"
				$request = [System.Net.HttpWebRequest]::Create($link)
				$request.Method = "GET"
				$response = $request.GetResponse()
				if ($response.StatusCode -eq [System.Net.HttpStatusCode]::OK) {
					if ($response.Headers["Content-Disposition"]) {
						$fileName = $response.Headers["Content-Disposition"].Replace("attachment; filename=", "").Replace('"', "");
					}
					else {
						$fileName = split-path $link -leaf
					}
					$stream = $response.GetResponseStream()
					$reader = [System.IO.StreamReader]::new($stream)
					
					$outFileName = join-path $Path $fileName
					
					write-verbose "    writing $outFileName"
					$outstream = [System.IO.File]::OpenWrite($outFileName);
					$stream.CopyTo($outstream);
					$outstream.Close();
					
					get-item $outFileName
				}
				$response.Close()
			}
		}
	}
	end {
	}
}

Export-ModuleMember -Function *
