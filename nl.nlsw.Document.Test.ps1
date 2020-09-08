#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.TestPeople.ps1
#
# @note this file must be UTF8-with-BOM, otherwise PS does not consider it Unicode.
#
#requires -version 5.1
#requires -modules nl.nlsw.TestSuite
using namespace nl.nlsw.Identifiers
using namespace nl.nlsw.Items

<#
.SYNOPSIS
 Test the functionality of the Powershell module nl.nlsw.Document.
  
.DESCRIPTION
 Runs functional tests of the functions and classes in the nl.nlsw.Document module.
 
.PARAMETER Quiet
 No output to the host

.NOTES
 @date 2020-09-08
 @author Ernst van der Pols
 @language PowerShell 5
#>
function Test-ModuleDocument {
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
		$suite | test-case "Module manifest nl.nlsw.Document.psd1" { Test-ModuleManifest "$PSScriptRoot\nl.nlsw.Document.psd1" | out-null; $? } $true

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

		# create a new Directory and test the initial state
		$directory = $( $suite | test-case "`$directory = new Items.Directory" { new-object nl.nlsw.Items.Directory } ([nl.nlsw.Items.Directory]) -passThru ).output
		$suite | test-case "Items.Directory initial state" { $directory.Count -eq 0 } $true
		# create a new ItemObject
		$item = $( $suite | test-case "`$item = `$directory.NewItem()" { $directory.NewItem("First Item") } ([nl.nlsw.Items.ItemObject]) -passThru ).output
		$suite | test-case "`$directory.Count == 1" { $directory.Count } 1
		$suite | test-case "`$directory[0].Identifier (index and Item.Identifier test)" { $directory[0].Identifier } $item.Identifier
		$suite | test-case "`$directory[`$item.Identifier].Identifier == `$item.Identifier (lookup test)" { $directory[$item.Identifier.ToString()].Identifier } $item.Identifier
		# test nl.nlsw.Items.ItemObject interface
		$suite | test-case "ItemObject.Directory" { $directory.Equals($item.Directory) } $true
		$suite | test-case "ItemObject.Name" { $item.Name } "First Item"
		$suite | test-case "ItemObject.HasProperties" { $item.HasProperties } $false
		$suite | test-case "ItemObject invalid interface access (exception)" { $item.Properties[0].GetFormattedName() } ([System.Exception])

	}
	end {
		# return the tests in the pipeline
		$suite | Write-TestResult -passThru
	}
}