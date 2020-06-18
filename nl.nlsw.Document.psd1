﻿#	_  _ ____ _ _ _ _    _ ____ ____    ____ ____ ____ ___ _ _ _ ____ ____ ____ 
#	|\ | |___ | | | |    | |___ |___    [__  |  | |___  |  | | | |__| |__/ |___ 
#	| \| |___ |_|_| |___ | |    |___    ___] |__| |     |  |_|_| |  | |  \ |___ 
#
# @file nl.nlsw.Document.psd1
#
# The nl.nlsw.Document module provides PowerShell document processing support.
#
@{
	GUID = "4f293aa5-d703-4ec6-bae7-16730a415dae"
	Author = "Ernst van der Pols"
	CompanyName = "NewLife Software"
	Copyright = "(c) Ernst van der Pols. All rights reserved."
	HelpInfoUri="http://www.nlsw.nl/?item=software"
	ModuleVersion = "1.0.0.3"
	PowerShellVersion="5.1"
	DotNetFrameworkVersion="4.5"
	CLRVersion="4.0"
	#RootModule=".\nl.nlsw.Document.ps1"
	Description="A PowerShell utility module for processing documents."
	NestedModules = @(
		".\nl.nlsw.Collections.ps1",
		".\nl.nlsw.Document.ps1",
		".\nl.nlsw.Document.Test.ps1",
		".\nl.nlsw.EPUB.ps1",
		".\nl.nlsw.Feed.ps1",
		".\nl.nlsw.FileSystem.ps1",
		".\nl.nlsw.Items.ps1"
		".\nl.nlsw.Process.Utility.ps1",
		".\nl.nlsw.XmlDocument.ps1"
	)
	FileList=@(
		".\nl.nlsw.Collections.ps1",
		".\nl.nlsw.Document.cs",
		".\nl.nlsw.Document.ps1",
		".\nl.nlsw.Document.Test.ps1",
		".\nl.nlsw.EPUB.ps1",
		".\nl.nlsw.Feed.ps1",
		".\nl.nlsw.FileSystem.ps1",
		".\nl.nlsw.Identifiers.cs",
		".\nl.nlsw.Items.cs",
		".\nl.nlsw.Items.ps1",
		".\nl.nlsw.Process.Utility.ps1",
		".\nl.nlsw.XmlDocument.ps1"
	)
	FunctionsToExport=@(
		"ConvertFrom-HashtableArray",
		"Get-MimeType","Get-ExtensionFromMimeType","Expand-ItemObjectMacros",
		"New-XmlDocument", "Add-XmlElement", "Add-XmlProcessingInstruction", "Add-XmlText",
		"New-XmlNamespaceManager",
		"Add-HtmlElement","New-HtmlDocument","Get-HtmlBody","Get-HtmlHead","Get-XmlNamespaces",
		"New-IncrementalFileName","New-TempFolder","Remove-TempFolder","Remove-ItemToRecycleBin",
		"Get-OSArchitecture", "Show-Assembly","Show-Module","Show-Object","Write-Action",
		"ConvertTo-EPUB",
		"Reed-Feed","Save-FeedAttachments",
		"Test-ModuleDocument"
	)
}
