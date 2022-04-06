<#
.SYNOPSIS
 Test the functionality of the PowerShell module nl.nlsw.Document.
  
.DESCRIPTION
 Runs functional tests of the functions and classes in the nl.nlsw.Document module.
 
.PARAMETER Quiet
 No output to the host

.NOTES
 @date 2022-04-05
 @author Ernst van der Pols
 @language PowerShell 5
#>
#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file Test-nl.nlsw.Document.ps1
# @copyright Ernst van der Pols, Licensed under the EUPL-1.2-or-later
# @note this file must be UTF8-with-BOM, otherwise WinPS does not consider it Unicode.
#
#requires -version 5.1
#requires -modules nl.nlsw.TestSuite
using namespace nl.nlsw.Identifiers
using namespace nl.nlsw.Items

[CmdletBinding()]
param ( 
	[Parameter(Mandatory=$False)]
	[switch]$Quiet
)
begin {
	# log the tests
	$suite = New-TestSuite "Module nl.nlsw.Document" -quiet:$Quiet
}
process {
	$suite | test-case "Module manifest nl.nlsw.Document.psd1" { Test-ModuleManifest "$PSScriptRoot\..\nl.nlsw.Document.psd1" | out-null; $? } $true

	$module = $( $suite | test-case "Import module nl.nlsw.Document" { Import-Module "nl.nlsw.Document" -passThru } ([System.Management.Automation.PSModuleInfo]) -passThru).output
	$suite | test-case "`$module.Name == 'nl.nlsw.Document'" { $module.Name } "nl.nlsw.Document"

	# test of nl.nlsw.Identifiers.UrnUri
	$urn = $( $suite | test-case "`$urn = new UrnUri('urn:isbn:9789032300937')" { ,[nl.nlsw.Identifiers.UrnUri]::New("urn:isbn:9789032300937") } ([nl.nlsw.Identifiers.UrnUri]) -passThru ).output
	$suite | test-case "`$urn.NID == 'isbn'" { $urn.NID } "isbn"
	$suite | test-case "`$urn.NSS" { $urn.NSS } "9789032300937"
	$suite | test-case "`$urn == new UrnUri('urn:ISBN:9789032300937')" { $urn } (new-object nl.nlsw.Identifiers.UrnUri "urn:ISBN:9789032300937")
	$suite | test-case "`$urn.ToString()" { $urn.ToString() } "urn:isbn:9789032300937"

	# test of nl.nlsw.Identifiers.TelUri
	$tel = $( $suite | test-case "`$tel = new TelUri('tel:+1-23-456789')" { ,[nl.nlsw.Identifiers.TelUri]::New("tel:+1-23-456789") } ([nl.nlsw.Identifiers.TelUri]) -passThru ).output
	$suite | test-case "`$tel.Number == +123456789" { $tel.Number } "+123456789"
	$suite | test-case "`$tel.IsGlobal" { $tel.IsGlobal } $true
	$suite | test-case "`$tel == new TelUri('tel:+123456789')" { $tel } (new-object nl.nlsw.Identifiers.TelUri "tel:+123456789")
	$suite | test-case "`$tel.ToString()" { $tel.ToString() } "tel:+1-23-456789"
	$tel = $( $suite | test-case "`$tel = new TelUri('tel:112;phone-context=+31')" { ,[nl.nlsw.Identifiers.TelUri]::New("tel:112;phone-context=+31") } ([nl.nlsw.Identifiers.TelUri]) -passThru ).output
	$suite | test-case "`$tel.Number == 112" { $tel.Number } "112"
	$suite | test-case "`$tel.IsGlobal (no)" { $tel.IsGlobal } $false
	$suite | test-case "`$tel == new TelUri('tel:1-1-2;phone-context:+3-1')" { $tel } (new-object nl.nlsw.Identifiers.TelUri "tel:1-1-2;phone-context=+3-1")
	$suite | test-case "`$tel.ToString()" { $tel.ToString() } "tel:112;phone-context=+31"

	# test of nl.nlsw.Items.CompoundValue
	$cv = $( $suite | test-case "`$cv = new CompoundValue()" { ,[nl.nlsw.Items.CompoundValue]::New("1,2,(3,4),5") } ([nl.nlsw.Items.CompoundValue]) -passThru ).output
	$suite | test-case "`$cv.Count == 4" { $cv.Count } 4
	$suite | test-case "`$cv[2].Count == 2" { $cv[2].Count } 2
	$suite | test-case "`$cv.ToString()" { $cv.ToString() } "1,2,(3,4),5"

	# test nl.nlsw.Items.Property interface
	$prop = $( $suite | test-case "new nl.nlsw.Items.Property" { new-object nl.nlsw.Items.Property } ([nl.nlsw.Items.Property]) -passThru ).output
	$suite | test-case "Property initial state" { !$prop.Name -and !$prop.Value -and !$prop.HasAttributes } $true
	$suite | test-case "Property.GetAttribute('Undefined','DefaultValue')" { $prop.GetAttribute('Undefined','DefaultValue') } "DefaultValue"
	$suite | test-case "Property.Attributes.Set('Defined','DefinedValue')" { $prop.Attributes.Set('Defined','DefinedValue'); $prop.GetAttribute('Defined','DefaultValue') } "DefinedValue"
	$suite | test-case "Property.HasAttributes" { $prop.HasAttributes } $true
	$suite | test-case "Property['Defined']" { $prop['Defined'] } "DefinedValue"
	$suite | test-case "Property.Name" { $prop.Name = "property"; $prop.Name } "property"
	$suite | test-case "Property.Value = `"waarde`"" { $prop.Value ="waarde"; $prop.Value } "waarde"

	# test nl.nlsw.Items.CompoundProperty interface
	$prop = $( $suite | test-case "new nl.nlsw.Items.CompoundProperty" { new-object nl.nlsw.Items.CompoundProperty } ([nl.nlsw.Items.CompoundProperty]) -passThru ).output
	$suite | test-case "CompoundProperty.Value = `"waarde`"" { $prop.Value ="waarde"; $prop.Value } "waarde"
	$suite | test-case "CompoundProperty.GetValue([0[,0]]) == `"waarde`"" { $prop.GetValue() -eq "waarde" -and $prop.GetValue(0) -eq "waarde" -and $prop.GetValue(0,0) -eq "waarde" } $true
	$suite | test-case "CompoundProperty.GetValue(0,1)" { $prop.GetValue(0,1) } $null
	$suite | test-case "CompoundProperty.AddValue(`"waarde2`",0)" { $prop.AddValue("waarde2",0); $prop.GetValue(0,1) } "waarde2"
	$suite | test-case "CompoundProperty.Value[1] = `"waarde3`" (index-out-of-range)" { $prop.Value[1] = "waarde3"; $prop.GetValue(1) } ([System.ArgumentOutOfRangeException])
	$suite | test-case "CompoundProperty.SetValue(`"waarde3`",1)" { $prop.SetValue("waarde3",1); $prop.GetValue(1) } "waarde3"
	$suite | test-case "CompoundProperty.AddValue(`"waarde4`",1)" { $prop.AddValue("waarde4",1); $prop.GetValue(1).ToString() } "(waarde3,waarde4)"
	$suite | test-case "CompoundProperty.GetValue(0,0)" { $prop.GetValue(0,0) } "waarde"
	$suite | test-case "CompoundProperty.Value.ToString() (compound value)" { $prop.Value.ToString() } "(waarde,waarde2),(waarde3,waarde4)"

	# create a new ItemList and test the initial state
	$ItemList = $( $suite | test-case "`$ItemList = new Items.ItemList" { new-object nl.nlsw.Items.ItemList } ([nl.nlsw.Items.ItemList]) -passThru ).output
	$suite | test-case "Items.ItemList initial state" { $ItemList.Count -eq 0 } $true
	# create a new ItemObject
	$item = $( $suite | test-case "`$item = `$ItemList.NewItem()" { $ItemList.NewItem("First Item") } ([nl.nlsw.Items.ItemObject]) -passThru ).output
	$suite | test-case "`$ItemList.Count == 1" { $ItemList.Count } 1
	$suite | test-case "`$ItemList[0].Identifier (index and Item.Identifier test)" { $ItemList[0].Identifier } $item.Identifier
	$suite | test-case "`$ItemList[`$item.Identifier].Identifier == `$item.Identifier (lookup test)" { $ItemList[$item.Identifier.ToString()].Identifier } $item.Identifier
	# test nl.nlsw.Items.ItemObject interface
	$suite | test-case "ItemObject.ItemList" { $ItemList.Equals($item.ItemList) } $true
	$suite | test-case "ItemObject.Name" { $item.Name } "First Item"
	$suite | test-case "ItemObject.HasProperties" { $item.HasProperties } $false
	$suite | test-case "ItemObject invalid interface access (exception)" { $item.Properties[0].GetFormattedName() } ([System.Exception])

}
end {
	# return the tests in the pipeline
	$suite | Write-TestResult -passThru
}
