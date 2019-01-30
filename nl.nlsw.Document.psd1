#	_  _ ____ _ _ _ _    _ ____ ____    ____ ____ ____ ___ _ _ _ ____ ____ ____ 
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
	ModuleVersion = "1.0.0.0"
	PowerShellVersion="5.1"
	DotNetFrameworkVersion="4.5"
	CLRVersion="4.0"
	#RootModule=".\nl.nlsw.Document.ps1"
	Description="A PowerShell utility module for processing documents."
	NestedModules = @(
		".\nl.nlsw.Document.ps1",
		".\nl.nlsw.XmlDocument.ps1",
		".\nl.nlsw.Process.Utility.ps1"
	)
	FunctionsToExport=@(
		"Get-MimeType","Get-ExtensionFromMimeType","New-IncrementalFileName",
		"New-XmlDocument", "Add-XmlElement", "Add-XmlText", "New-XmlNamespaceManager",
		"New-TempFolder","Remove-TempFolder","Show-Assembly","Show-Module","Show-Object","Write-Action"
	)
}
