#	_  _ ____ _ _ _ _    _ ____ ____    ____ ____ ____ ___ _ _ _ ____ ____ ____
#	|\ | |___ | | | |    | |___ |___    [__  |  | |___  |  | | | |__| |__/ |___
#	| \| |___ |_|_| |___ | |    |___    ___] |__| |     |  |_|_| |  | |  \ |___
#
# @file nl.nlsw.Document.psd1
#
# The nl.nlsw.Document module provides PowerShell document processing support.
#
@{
	# Script module or binary module file associated with this manifest.
	# RootModule = ".\nl.nlsw.Document.psm1"

	# Version number of this module.
	ModuleVersion = "1.1.0"

	# Supported PSEditions
	# CompatiblePSEditions = @()

	# ID used to uniquely identify this module
	GUID = "4f293aa5-d703-4ec6-bae7-16730a415dae"

	# Author of this module
	Author = "Ernst van der Pols"

	# Company or vendor of this module
	CompanyName = "NewLife Software"

	# Copyright statement for this module
	Copyright = "(c) Ernst van der Pols. All rights reserved."

	# Description of the functionality provided by this module
	Description = "A PowerShell/.NET utility package for processing documents."

	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion = "5.1"

	# Name of the Windows PowerShell host required by this module
	# PowerShellHostName = ''

	# Minimum version of the Windows PowerShell host required by this module
	# PowerShellHostVersion = ''

	# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
	DotNetFrameworkVersion = "4.5"

	# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
	CLRVersion = "4.0"

	# Processor architecture (None, X86, Amd64) required by this module
	# ProcessorArchitecture = ''

	# Modules that must be imported into the global environment prior to importing this module
	# RequiredModules = @()

	# Assemblies that must be loaded prior to importing this module
	# RequiredAssemblies = @()

	# Script files (.ps1) that are run in the caller's environment prior to importing this module.
	# ScriptsToProcess = @()

	# Type files (.ps1xml) to be loaded when importing this module
	# TypesToProcess = @()

	# Format files (.ps1xml) to be loaded when importing this module
	# FormatsToProcess = @()

	# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
	NestedModules = @(
		"./nl.nlsw.Collections.psm1",
		"./nl.nlsw.Document.psm1",
		"./nl.nlsw.EPUB.psm1",
		"./nl.nlsw.Feed.psm1",
		"./nl.nlsw.JSON.psm1",
		"./nl.nlsw.FileSystem.psm1",
		"./nl.nlsw.Ini.psm1",
		"./nl.nlsw.Items.psm1"
		"./nl.nlsw.SQLite.psm1"
		"./nl.nlsw.XmlDocument.psm1"
	)

	# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
	FunctionsToExport = @(
		"ConvertFrom-HashtableArray","ConvertTo-OrderedDictionary",
		"Get-MimeType","Get-ExtensionFromMimeType","Expand-ItemObjectMacro",
		"New-XmlDocument", "Add-XmlElement", "Add-XmlProcessingInstruction", "Add-XmlText",
		"New-XmlNamespaceManager",
		"Add-HtmlElement","New-HtmlDocument","Get-HtmlBody","Get-HtmlHead","Get-XmlNamespace",
		"Get-ValidFileName","Move-VersionControlledFile","New-IncrementalFileName","New-TempFolder","Remove-TempFolder","Remove-ItemToRecycleBin","Test-VersionControlledFile"
		"Export-Ini","Import-Ini",
		"ConvertTo-EPUB",
		"ConvertTo-FormattedJson",
		"Get-SQLiteDataSet","Invoke-SQLiteCommand",
		"Read-Feed","Save-FeedAttachment"
	)

	# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
	CmdletsToExport = @()

	# Variables to export from this module
	VariablesToExport = @()

	# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
	AliasesToExport = @()

	# DSC resources to export from this module
	# DscResourcesToExport = @()

	# List of all modules packaged with this module
	# ModuleList = @()

	# List of all files packaged with this module
	FileList=@(
		"./en/about_nl.nlsw.Document.help.txt",
		"./lib/netstandard2.0/nl.nlsw.Document.dll",
		"./source/nl.nlsw.Document.cs",
		"./source/nl.nlsw.Identifiers.cs",
		"./source/nl.nlsw.Items.cs",
		"./tests/Test-nl.nlsw.Document.ps1",
		"./nl.nlsw.Collections.psm1",
		"./nl.nlsw.Document.psm1",
		"./nl.nlsw.EPUB.psm1",
		"./nl.nlsw.JSON.psm1",
		"./nl.nlsw.Feed.psm1",
		"./nl.nlsw.FileSystem.psm1",
		"./nl.nlsw.Ini.psm1",
		"./nl.nlsw.Items.psm1",
		"./nl.nlsw.XmlDocument.psm1"
	)

	# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData = @{

		PSData = @{

			# Tags applied to this module. These help with module discovery in online galleries.
			Tags = @('Document','ItemObject','ItemList','ItemStack','Property','Attributes','CompoundProperty','Reader','Writer','URI', 'EPUB', 'PSEdition_Desktop')

			# A URL to the license for this module.
			LicenseUri = 'https://spdx.org/licenses/EUPL-1.2.html'

			# A URL to the main website for this project.
			ProjectUri = 'https://github.com/nl-software/nl.nlsw.Document'

			# A URL to an icon representing this module.
			# IconUri = ''

			# ReleaseNotes of this module
			# ReleaseNotes = ''

		} # End of PSData hashtable

	} # End of PrivateData hashtable

	# HelpInfo URI of this module
	# HelpInfoUri = "http://www.nlsw.nl/?item=software"

	# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
	# DefaultCommandPrefix = ''
}
