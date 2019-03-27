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
 @date 2019-03-27
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

		# create a new Dictionary and test the initial state
		$directory = $( $suite | test-case "`$directory = new People.Directory" { New-PeopleDirectory } ([nl.nlsw.People.Directory]) -passThru ).output
		$suite | test-case "People.Directory initial state" { $directory.Count -eq 0 } $true
		# create a new Person
		$person = $( $suite | test-case "`$person = `$directory.NewPerson()" { $directory.NewPerson("First Person") } ([nl.nlsw.People.Person]) -passThru ).output
		$suite | test-case "`$directory.Count == 1" { $directory.Count } 1
		$suite | test-case "`$directory[0].ID (index and Person.ID test)" { $directory[0].ID } $person.ID
		$suite | test-case "`$directory[`$person.ID].ID == `$person.ID (lookup test)" { $directory[$person.ID.ToString()].ID } $person.ID
		# test Person interface
		$suite | test-case "Person.Directory" { $directory.Equals($person.Directory) } $true
		$suite | test-case "Person.Kind" { $person.Kind } ([nl.nlsw.People.Kind]::Individual)
		$suite | test-case "Person.Name" { $person.Name } "First Person"
		$suite | test-case "Person.FormatType" { $person.FormatType } ([nl.nlsw.People.FormatType]::None)
		$suite | test-case "Person.GenderType" { $person.GenderType } ([nl.nlsw.People.GenderType]::None)
		$suite | test-case "Person.HasProperties" { $person.HasProperties } $false
		$suite | test-case "Person.HasEvents" { $person.HasEvents } $false
		$suite | test-case "Person.HasRelations" { $person.HasRelations } $false
		$suite | test-case "Person invalid interface access (exception)" { $person.Properties[0].GetFormattedName() } ([System.Exception])
		# test of CompoundValue
		$cv = $( $suite | test-case "`$cv = new CompoundValue()" { ,[nl.nlsw.Items.CompoundValue]::New("1,2,(3,4),5") } ([nl.nlsw.Items.CompoundValue]) -passThru ).output
		$suite | test-case "`$cv.Count == 4" { $cv.Count } 4
		$suite | test-case "`$cv[2].Count == 2" { $cv[2].Count } 2
		$suite | test-case "`$cv.ToString()" { $cv.ToString() } "1,2,(3,4),5"
		
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
		
		# test Property interface
		$prop = $( $suite | test-case "new People.Property" { new-object nl.nlsw.People.Property } ([nl.nlsw.People.Property]) -passThru ).output
		$suite | test-case "Property initial state" { !$prop.Name -and !$prop.Value -and !$prop.HasAttributes } $true
		$suite | test-case "Property.GetAttribute('Undefined','DefaultValue')" { $prop.GetAttribute('Undefined','DefaultValue') } "DefaultValue"
		$suite | test-case "Property.Attributes.Set('Defined','DefinedValue')" { $prop.Attributes.Set('Defined','DefinedValue'); $prop.GetAttribute('Defined','DefaultValue') } "DefinedValue"
		$suite | test-case "Property.HasAttributes" { $prop.HasAttributes } $true
		$suite | test-case "Property['Defined']" { $prop['Defined'] } "DefinedValue"
		$suite | test-case "Property.Name" { $prop.Name = "property"; $prop.Name } "property"
		$suite | test-case "Property.Value = `"waarde`"" { $prop.Value ="waarde"; $prop.Value } "waarde"
		# test CompoundProperty interface
		$prop = $( $suite | test-case "new People.CompoundProperty" { new-object nl.nlsw.People.CompoundProperty } ([nl.nlsw.People.CompoundProperty]) -passThru ).output
		$suite | test-case "CompoundProperty.Value = `"waarde`"" { $prop.Value ="waarde"; $prop.Value } "waarde"
		$suite | test-case "CompoundProperty.GetValue([0[,0]]) == `"waarde`"" { $prop.GetValue() -eq "waarde" -and $prop.GetValue(0) -eq "waarde" -and $prop.GetValue(0,0) -eq "waarde" } $true
		$suite | test-case "CompoundProperty.GetValue(0,1)" { $prop.GetValue(0,1) } $null
		$suite | test-case "CompoundProperty.AddValue(`"waarde2`",0)" { $prop.AddValue("waarde2",0); $prop.GetValue(0,1) } "waarde2"
		$suite | test-case "CompoundProperty.Value[1] = `"waarde3`" (index-out-of-range)" { $prop.Value[1] = "waarde3"; $prop.GetValue(1) } ([System.ArgumentOutOfRangeException])
		$suite | test-case "CompoundProperty.SetValue(`"waarde3`",1)" { $prop.SetValue("waarde3",1); $prop.GetValue(1) } "waarde3"
		$suite | test-case "CompoundProperty.AddValue(`"waarde4`",1)" { $prop.AddValue("waarde4",1); $prop.GetValue(1).ToString() } "(waarde3,waarde4)"
		$suite | test-case "CompoundProperty.GetValue(0,0)" { $prop.GetValue(0,0) } "waarde"
		$suite | test-case "CompoundProperty.Value.ToString() (compound value)" { $prop.Value.ToString() } "(waarde,waarde2),(waarde3,waarde4)"

		# test NameProperty interface
		$nameprop = $( $suite | test-case "new People.NameProperty" { new-object nl.nlsw.People.NameProperty } ([nl.nlsw.People.NameProperty]) -passThru ).output
		$suite | test-case "NameProperty.Name" { $nameprop.Name = "n"; $nameprop.Name } "n"
		$suite | test-case "NameProperty.GivenName" { $nameprop.GivenName = "John"; $nameprop.GivenName } "John"
		$suite | test-case "NameProperty.FamilyName" { $nameprop.FamilyName = "Claassen"; $nameprop.FamilyName } "Claassen"
		$suite | test-case "Person.Properties.Add" { $person.Properties.Add($nameprop) } $null
		$suite | test-case "NameProperty.GetFormattedName()" { $nameprop.GetFormattedName() } "John Claassen"
		$suite | test-case "Person.Properties[0].GetFormattedName()" { $person.Properties[0].GetFormattedName() } "John Claassen"

		# test Import-vCard with (all) specifics of each version
		$vcardTS = $( $suite | test-case "`$vcardTS = Import-vCard (basic decoding)" { $vCardTestSource | Import-vCard -verbose } ([nl.nlsw.People.Directory]) -passThru ).output
		$suite | test-case "`$vcardTS.Count == 5" { $vcardTS.Count } 5
		# check version 2.1 result
		$suite | test-case "`$vcardTS[0].Name (vCard21)" { $vcardTS[0].Name } "vCard 2.1 Test Case"
		$suite | test-case "`$vcardTS[0].FormatType" { $vcardTS[0].FormatType } ([nl.nlsw.People.FormatType]::vCard21)
		$suite | test-case "`$vcardTS[0]['fn'][1]" { $vcardTS[0].Properties['FN'][1].Value } "Mr. John Q. Public Jr., Esq."
		$suite | test-case "`$vcardTS[0]['uid'].uri.scheme" { $vcardTS[0]['uid'].Uri.Scheme } "urn"
		$suite | test-case "`$vcardTS[0]['uid'].Uri" { $vcardTS[0]['uid'].Uri } "urn:example:nl.nlsw.People.TestCase.vCard21"

		# N has only a single depth compound value
		$suite | test-case "`$vcardTS[0]['n']" { $n = $vcardTS[0]['n']; ($n.FamilyName -eq "Public") -and ($n.GivenName -eq "John") -and $n.AdditionalName -eq "Quinlan" -and $n.Prefix -eq "Mr." -and $n.Suffix -eq "Jr., Esq." } $true
		$suite | test-case "`$vcardTS[0]['adr'][0] (default=work,ASCII,7bit)" { $vcardTS[0]['adr'][0].GetAttribute('type') } "work,intl,postal,parcel"
		$suite | test-case "`$vcardTS[0]['adr'][0].PostOfficeBox" { $vcardTS[0]['adr'][0].PostOfficeBox } "P.O. Box 101"
		$suite | test-case "`$vcardTS[0]['adr'][0].Locality" { $vcardTS[0]['adr'][0].Locality } "Any Town"
		$suite | test-case "`$vcardTS[0]['adr'][0].Region" { $vcardTS[0]['adr'][0].Region } "CA"
		$suite | test-case "`$vcardTS[0]['adr'][0].PostalCode" { $vcardTS[0]['adr'][0].PostalCode } "91921-1234"
		$suite | test-case "`$vcardTS[0]['adr'][0].CountryName" { $vcardTS[0]['adr'][0].CountryName } $null
		$suite | test-case "`$vcardTS[0]['label'] (default=work, QP)" { $label = $vcardTS[0]['label'][0]; if ($label.GetAttribute('type') -eq 'intl,postal,parcel,work') { $label.Value } } "P.O. Box 101`r`nAny Town, CA 91921-1234"
		$suite | test-case "`$vcardTS[0]['adr'][1] (home,ASCII,7bit)" { $adr = $vcardTS[0].GetProperties('adr','group','home')[0]; ($adr.GetAttribute('type') -eq 'dom,work,home,postal')  } $true
		$suite | test-case "`$vcardTS[0]['adr'][1].PostOfficeBox" { $vcardTS[0]['adr'][1].PostOfficeBox } ""
		$suite | test-case "`$vcardTS[0]['adr'][1].ExtendedAddress" { $vcardTS[0]['adr'][1].ExtendedAddress } "Suite 101"
		$suite | test-case "`$vcardTS[0]['adr'][1].StreetAddress" { $vcardTS[0]['adr'][1].StreetAddress } "123 Main Street"
		$suite | test-case "`$vcardTS[0]['adr'][1].Locality" { $vcardTS[0]['adr'][1].Locality } "Any Town"
		$suite | test-case "`$vcardTS[0]['adr'][1].Region" { $vcardTS[0]['adr'][1].Region } "CA"
		$suite | test-case "`$vcardTS[0]['adr'][1].PostalCode" { $vcardTS[0]['adr'][1].PostalCode } "91921-1234"
		$suite | test-case "`$vcardTS[0]['adr'][1].CountryName" { $vcardTS[0]['adr'][1].CountryName } "USA"
		$suite | test-case "`$vcardTS[0]['label'] (home, QP)" { $label = $vcardTS[0].GetProperties('label','group','home')[0]; if ($label.GetAttribute('type') -eq 'dom,work,home,postal') { $label.Value } } "Suite 101`r`n123 Main Street`r`nAny Town, CA 91921-1234"
		$suite | test-case "`$vcardTS[0]['adr'][2].StreetAddress (canda:QP,de)" { $vcardTS[0]['adr'][2].StreetAddress } "Kurfürstendamm 227-229"
		$suite | test-case "`$vcardTS[0]['label'] (canda:iso-8859-1,QP)" { $label = $vcardTS[0].GetProperties('label','group','canda')[0]; if ($label.GetAttribute('type') -eq 'work') { $label.Value } } "Kurfürstendamm 227-229`r`n10719 Berlin`r`nDeutschland"
		$suite | test-case "`$vcardTS[0]['adr'][3].StreetAddress (cartier:B,fr)" { $vcardTS[0]['adr'][3].StreetAddress } "154 Av. des Champs-Élysées"
		$suite | test-case "`$vcardTS[0]['adr'][4].StreetAddress (coop:utf-8,8bit)" { $vcardTS[0]['adr'][4].StreetAddress } "Mühlackerstrasse 199"

		$suite | test-case "`$vcardTS[0]['bday'].DateTime" { $vcardTS[0]['bday'].DateTime.ToString("o") } "1995-04-15T00:00:00.0000000"
		$suite | test-case "`$vcardTS[0]['photo'].Uri" { $vcardTS[0]['photo'].Uri } "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKQAAAB1CAMAAAD3Cbr5AAAAmVBMVEX////tgSMAAAD51bX4z6zxoFn86dj73sb0sXbzq2398eb+9/GhoaEWFhZ+fn6/v78nJyf29vaVlZXMzMyIiIg/Pz9SUlJycnL2wJAJCQnGxsZnZ2f7487n5+dpaWlgYGDuiTLxnFOysrLt7e00NDRDQ0OdnZ1MTEx4eHgxMTGpqand3d34y6T51LT1uIMYGBj3w5fvlERXV1d4FkJPAAADjElEQVR4nO2a63aiMBCAMXbFqkAppRWtd7xbbfv+D7czAYRAENemGzxnvj8YMPBlkkxyFMMgCIIgCM28m+a7bofLtI7TBjA9tnSblNNsnPnQ7VJGq5GhrrGcZSVnum3kCIGsaygPouRBt4+Uoyh51O0jpS1KtnX7SMlJPur2kXIXkbyLMXkXszuXJ2u6zbiHFec+1m7jI3Ws7S4o3U+2axvHiPrvzIkf0f38c4FDV7cf0pw2LjI1dRsKaaeMpm7HbkUceSx19/hDtWOj8aBZsl2tqH/X9niNpO79L0mSZE0lZ18yua9ZrSS70nzZ7JDkL0qOHGdUddeBw/GKV6D2PleALyuXfGHsuUrSYhGnXf7KjrHNudBjzDaMJ8ZcnZLFr9ZKMnCcub1kzKqW3EwmuiT5EYI0qJSs5nbJZzBgfjTm3RcoWPY5IInkhLGdMff9HhZs39+j5CmAitvBWfI7DLGi9wrnA2lQb5V0/XjQ4dRwl9HnMHlCIjlmrGes4ni9MuahZIwjjkkniE6rlBxCq30f7h8sYFTBYTgJ0s7LSO4Kkk+2PYaZFQqSLpx58v1wq7C73YAFmC0hhCvDOPGh5/EHC5I+Biwv+QafR9CiRVYS5WV+P5EEoTUWVjgP9jDEsLCN1eLZ7TjfEGFXKmmssV0ZybdLc+hGSYexIRbm+Mw9TiAgxOjEkgm2IZecYIwzkmPeJb8mOcawJoxEyWDolkvOs5JDnGL/XdK27V60dtdBknc3zFiOm0gGaYVru1ulpI2jZ8DYKxb4Y0aMLcW75iU3BUnJxClfx/5Z0uVpZQELRxyQHXdalEs6cRvWGcl9PgX1Cg29XXKJ+RtHHoTFt21wxAkNB2sDnb1OekyQhJzK/PEbVuSSJ74I5JM5fOnb3ixVJHO+dvFsnEzgFyyc0oRTlMQBEuOhV8xcXBZX8WklklYYjZ39GlNMvMEYRSv5NtnjipIYdhaMxyjpxY3bYsWdZUEbwyDA+bbCK8FaHDcR/WskP2XNg82/l+4G3IEju33MflB+LcVzSvaVrSskp51rHvGbmNOcZMvMS2r/EdUwug/9fr9EsguXDvX5T0cuqdsqB0mqgiRVQZKqIElVkKQqSFIVJKkKklQFSaqCJFVBkqogSVWQpCpIUhV3IWnKJGvwDqpA+rJnKqn95c4C5rQgKf+pXCudfvQ6dKcVHdt1G5EEQRAEQRBEbfgLkupMc2v19OQAAAAASUVORK5CYII="
		$suite | test-case "`$vcardTS[0]['rev'].DateTime" { $vcardTS[0]['rev'].DateTime.ToString("o") } "1995-10-31T22:27:10.0000000Z"
		$suite | test-case "`$vcardTS[0]['tel'].Value" { $vcardTS[0]['tel'].Value } "(0111) 11 22 33"
		$suite | test-case "`$vcardTS[0]['email'][0].Uri" { $vcardTS[0]['email'][0].Uri } "mailto:john.public@abc.com"
		$suite | test-case "`$vcardTS[0]['email'][1].Uri" { $vcardTS[0]['email'][1].Uri } "mailto:%22Fred%5C%20Flintstone%5C%40Rockville%22@[2001:0db8:85a3:0000:0000:8a2e:0370:7334]"
		$suite | test-case "`$vcardTS[0]['email'][2].Uri" { $vcardTS[0]['email'][2].Uri } "mailto:!def!xyz%25abc@example.com"
		$suite | test-case "`$vcardTS[0]['mailer']" { $vcardTS[0]['mailer'].Value } "ccMail 2.2"
		$suite | test-case "`$vcardTS[0]['tz']" { $vcardTS[0]['tz'].Value } "+0200"
		$suite | test-case "`$vcardTS[0]['geo']" { $vcardTS[0]['geo'].Value } "geo:37.24,-17.87"
		$suite | test-case "`$vcardTS[0]['title']" { $vcardTS[0]['title'].Value } "Vice President, Research and Development"
		$suite | test-case "`$vcardTS[0]['role']" { $vcardTS[0]['role'].Value } "Executive"
		$suite | test-case "`$vcardTS[0]['logo'].Uri" { $vcardTS[0]['logo'].Uri } "data:image/gif;base64,R0lGODdhfgA4AOYAAAAAAK+vr62trVIxa6WlpZ+fnzEpCEpzlAha/0Kc74+PjyGMSuecKRhrtX9/fzExORBSjCEYCGtra2NjYyF7nDGE50JrhAg51qWtOTl7vee1MWu150o5e3PO/3sxcwAx/4R7GBgQOcDAwFoAQt61hJyMGHuUSpRKIf8A/wAY54yMjHtz"
		$suite | test-case "`$vcardTS[0]['org'] (Name)" { $vcardTS[0]['org'].Value[0] } "ABC, Inc."
		$suite | test-case "`$vcardTS[0]['org'] (Unit)" { $vcardTS[0]['org'].Value[1] } "North American Division"
		$suite | test-case "`$vcardTS[0]['org'] (Unit)" { $vcardTS[0]['org'].Value[2] } "Marketing"
		$suite | test-case "`$vcardTS[0]['url'].Uri" { $vcardTS[0]['url'].Uri } "http://www.example.com/users/user/contacts.php?item=personen%3APersoon&action=vcard"
		$suite | test-case "`$vcardTS[0]['note'][0]" { $vcardTS[0]['note'][0].Value } "encoding=Quoted-Printable="
		$suite | test-case "`$vcardTS[0]['sound'].Uri" { $vcardTS[0]['sound'].Uri } $null
		$suite | test-case "`$vcardTS[0]['sound'].Value" { $vcardTS[0]['sound'].Value } "JON Q PUBLIK"
		$suite | test-case "`$vcardTS[0]['key'].Uri" { $vcardTS[0]['key'].Uri } "data:application/octet-stream;base64,MIICajCCAdOgAwIBAgICBEUwDQYJKoZIhvcNAQEEBQAwdzELMAkGA1UEBhMCVVMxLDAqBgNVBAoTI05ldHNjYXBlIENbW11bmljYXRpb25zIENvcnBvcmF0aW9uMRwwGgYDVQQLExNJbmZvcm1hdGlvbiBTeXN0ZW1zMRwwGgYDVQQDExNyb290Y2EubmV0c2NhcGUuY29tMB4XDTk3MDYwNjE5NDc1OVoXDTk3MTIwMzE5NDc1OVowgYkxCzAJBgNVBAYTAlVTMSYwJAYDVQQKEx1OZXRzY2FwZSBDb21tdW5pY2F0aW9ucyBDb3JwLjEYMBYGA1UEAxMPVGltb3RoeSBBIEhvd2VzMSEwHwYJKoZIhvcNAQkBFhJob3dlc0BuZXRzY2FwZS5jb20xFTATBgoJkiaJk/IsZAEBEwVob3dlczBcMA0GCSqGSIb3DQEBAQUAA0sAMEgCQQC0JZf6wkg8pLMXHHCUvMfL5H6zjSk4vTTXZpYyrdN2dXcoX49LKiOmgeJSzoiFKHtLOIboyludF90CgqcxtwKnAgMBAAGjNjA0MBEGCWCGSAGG+EIBAQQEAwIAoDAfBgNVHSMEGDAWgBT84FToB/GV3jr3mcau+hUMbsQukjANBgkqhkiG9w0BAQQFAAOBgQBexv7o7mi3PLXadkmNP9LcIPmx93HGp0Kgyx1jIVMyNgsemeAwBM+MSlhMfcpbTrONwNjZYW8vJDSoi//yrZlVt9bJbs7MNYZVsyF1unsqaln4/vy6Uawfg8VUMk1U7jt8LYpo4YULU7UZHPYVUaSgVttImOHZIKi4hlPXBOhcUQ=="
		$suite | test-case "`$vcardTS[0]['agent']" { $vcardTS[0]['agent'].Person.Name } "Fred Friday"
		
		# nested vCard
		$suite | test-case "`$vcardTS[1].Name == Fred Friday" { $vcardTS[1].Name } "Fred Friday"

		# check version 3.0 result
		$suite | test-case "`$vcardTS[2].Name (vCard30)" { $vcardTS[2].Name } "vCard 3.0 Test Case"
		$suite | test-case "`$vcardTS[2].FormatType" { $vcardTS[2].FormatType } ([nl.nlsw.People.FormatType]::vCard30)
		$suite | test-case "`$vcardTS[2]['fn'][1].Value" { $vcardTS[2]['fn'][1].Value } "Dr. John P.P. Stevenson Jr., M.D., A.C.P."
		$suite | test-case "`$vcardTS[2]['n'].ToString()" { $vcardTS[2]['n'].ToString() } "Dr. John Philip Paul Stevenson Jr. M.D. A.C.P."
		$suite | test-case "`$vcardTS[2]['n'].ToString()" { $vcardTS[2]['n'].Value.ToString() } "Stevenson,John,(Philip,Paul),Dr.,(Jr.,M.D.,A.C.P.)"
		$suite | test-case "`$vcardTS[2]['n'].FamilyName" { $vcardTS[2]['n'].FamilyName } "Stevenson"
		$suite | test-case "`$vcardTS[2]['n'].GivenName" { $vcardTS[2]['n'].GivenName } "John"
		$suite | test-case "`$vcardTS[2]['n'].AdditionalNames" { $vcardTS[2]['n'].AdditionalNames.ToString() } "(Philip,Paul)"
		$suite | test-case "`$vcardTS[2]['n'].Prefix" { $vcardTS[2]['n'].Prefix } "Dr."
		$suite | test-case "`$vcardTS[2]['n'].Suffixes" { $vcardTS[2]['n'].Suffixes.ToString() } "(Jr.,M.D.,A.C.P.)"
		$suite | test-case "`$vcardTS[2]['nickname'].Value.ToString()" { $vcardTS[2]['nickname'].Value.ToString() } "Jim,Jimmie"
		$suite | test-case "`$vcardTS[2]['photo'][0].Uri" { $vcardTS[2]['photo'][0].Uri } "http://www.abc.com/pub/photos/jqpublic.gif"
		$suite | test-case "`$vcardTS[2]['photo'][0].GetAttribute('type')" { $vcardTS[2]['photo'][0].GetAttribute('type') } "gif"
		$suite | test-case "`$vcardTS[2]['photo'][1].Uri" { $vcardTS[2]['photo'][1].Uri } "data:image/jpeg;base64,MIICajCCAdOgAwIBAgICBEUwDQYJKoZIhvcNAQEEBQAwdzELMAkGA1UEBhMCVVMxLDAqBgNVBAoTI05ldHNjYXBlIENvbW11bmljYXRpb25zIENvcnBvcmF0aW9uMRwwGgYDVQQLExNJbmZvcm1hdGlvbiBTeXN0"
		$suite | test-case "`$vcardTS[2]['bday'].DateTime" { $vcardTS[2]['bday'].DateTime.ToString("o") } "1953-10-15T23:10:00.0000000Z"
		$suite | test-case "`$vcardTS[2]['adr'].Attributes" { $vcardTS[2]['adr'].GetAttribute('type') } "dom,home,postal,parcel"
		$suite | test-case "`$vcardTS[2]['adr'].PostOfficeBox" { $vcardTS[2]['adr'].PostOfficeBox } ""
		$suite | test-case "`$vcardTS[2]['adr'].ExtendedAddress" { $vcardTS[2]['adr'].ExtendedAddress } ""
		$suite | test-case "`$vcardTS[2]['adr'].StreetAddress" { $vcardTS[2]['adr'].StreetAddress } "123 Main Street"
		$suite | test-case "`$vcardTS[2]['adr'].Locality" { $vcardTS[2]['adr'].Locality } "Any Town"
		$suite | test-case "`$vcardTS[2]['adr'].Region" { $vcardTS[2]['adr'].Region } "CA"
		$suite | test-case "`$vcardTS[2]['adr'].PostalCode" { $vcardTS[2]['adr'].PostalCode } "91921-1234"
		$suite | test-case "`$vcardTS[2]['adr'].CountryName" { $vcardTS[2]['adr'].CountryName } $null
		$suite | test-case "`$vcardTS[2]['label']" { $label = $vcardTS[2]['label']; if ($label.GetAttribute('type') -eq 'dom,home,postal,parcel') { $label.Value } } "Mr.John Q. Public, Esq.`r`nMail Drop: TNE QB`r`n123 Main Street`r`nAny Town, CA  91921-1234`r`nU.S.A."
		$suite | test-case "`$vcardTS[2]['tel'].Uri" { $vcardTS[2]['tel'].Uri } "tel:+1-213-555-1234"
		$suite | test-case "`$vcardTS[2]['tel'].GetAttribute('type')" { $vcardTS[2]['tel'].GetAttribute('type') } "work,voice,pref,msg"
		$suite | test-case "`$vcardTS[2]['email'].Uri" { $vcardTS[2]['email'].Uri } "mailto:jppstevens@n.jr.com"
		$suite | test-case "`$vcardTS[2]['mailer']" { $vcardTS[2]['mailer'].Value } "PigeonMail 2.1"
		$suite | test-case "`$vcardTS[2]['tz']" { $vcardTS[2]['tz'].Value } "-05:00; EST; Raleigh/North America"
		$suite | test-case "`$vcardTS[2]['geo']" { $vcardTS[2]['geo'].Uri } "geo:37.386013,-122.082932"
		$suite | test-case "`$vcardTS[2]['title']" { $vcardTS[2]['title'].Value } "Director, Research and Development"
		$suite | test-case "`$vcardTS[2]['role']" { $vcardTS[2]['role'].Value } "Programmer"
		$suite | test-case "`$vcardTS[2]['logo']" { $vcardTS[2]['logo'].Uri } "http://www.abc.com/pub/logos/abccorp.jpg"
		$suite | test-case "`$vcardTS[2]['agent']" { $vcardTS[2]['agent'].Person.Name } "Susan Thomas"
		$suite | test-case "`$vcardTS[2]['org'].Organization" { $vcardTS[2]['org'].Value[0] } "ABC, Inc."
		$suite | test-case "`$vcardTS[2]['org'].Unit[0]" { $vcardTS[2]['org'].Value[1] } "North American Division"
		$suite | test-case "`$vcardTS[2]['org'].Unit[1]" { $vcardTS[2]['org'].Value[2] } "Marketing"
		$suite | test-case "`$vcardTS[2]['categories'].Value" { $vcardTS[2]['categories'].Value -join "," } "INTERNET,IETF,INDUSTRY,INFORMATION TECHNOLOGY"
		$suite | test-case "`$vcardTS[2]['note'].Value" { $vcardTS[2]['note'].Value } "This fax number is operational 0800 to 1715 EST, Mon-Fri."
		$suite | test-case "`$vcardTS[2]['prodid'].Uri" { $vcardTS[2]['prodid'].Uri } "urn:publicid:-:ONLINE+DIRECTORY:NONSGML+Version+1:EN"
		$suite | test-case "`$vcardTS[2]['prodid'].PublicIdentifier" { $vcardTS[2]['prodid'].PublicIdentifier } "-//ONLINE DIRECTORY//NONSGML Version 1//EN"
		$suite | test-case "`$vcardTS[2]['rev'].DateTime" { $vcardTS[2]['rev'].DateTime.ToString("o") } "1995-10-31T22:27:10.0000000Z"
		$suite | test-case "`$vcardTS[2]['sort-string'].Value" { $vcardTS[2]['sort-string'].Value } "Stevenson"
		$suite | test-case "`$vcardTS[2]['sound'].Uri" { $vcardTS[2]['sound'].Uri } "data:audio/basic;base64,MIICajCCAdOgAwIBAgICBEUwDQYJKoZIhvcNAQEEBQAwdzELMAkGA1UEBhMCVVMxLDAqBgNVBAoTI05ldHNjYXBlIENvbW11bmljYXRpb25zIENvcnBvcmF0aW9uMRwwGgYDVQQLExNJbmZvcm1hdGlvbiBTeXN0"
		$suite | test-case "`$vcardTS[2]['url'].Uri" { $vcardTS[2]['url'].Uri } "http://www.swbyps.restaurant.french/~chezchic.html"
		$suite | test-case "`$vcardTS[2]['class'].Value" { $vcardTS[2]['class'].Value } "CONFIDENTIAL"
		$suite | test-case "`$vcardTS[2]['key'].Uri" { $vcardTS[2]['key'].Uri } "data:application/octet-stream;base64,MIICajCCAdOgAwIBAgICBEUwDQYJKoZIhvcNAQEEBQAwdzELMAkGA1UEBhMCVVMxLDAqBgNVBAoTI05ldHNjYXBlIENbW11bmljYXRpb25zIENvcnBvcmF0aW9uMRwwGgYDVQQLExNJbmZvcm1hdGlvbiBTeXN0ZW1zMRwwGgYDVQQDExNyb290Y2EubmV0c2NhcGUuY29tMB4XDTk3MDYwNjE5NDc1OVoXDTk3MTIwMzE5NDc1OVowgYkxCzAJBgNVBAYTAlVTMSYwJAYDVQQKEx1OZXRzY2FwZSBDb21tdW5pY2F0aW9ucyBDb3JwLjEYMBYGA1UEAxMPVGltb3RoeSBBIEhvd2VzMSEwHwYJKoZIhvcNAQkBFhJob3dlc0BuZXRzY2FwZS5jb20xFTATBgoJkiaJk/IsZAEBEwVob3dlczBcMA0GCSqGSIb3DQEBAQUAA0sAMEgCQQC0JZf6wkg8pLMXHHCUvMfL5H6zjSk4vTTXZpYyrdN2dXcoX49LKiOmgeJSzoiFKHtLOIboyludF90CgqcxtwKnAgMBAAGjNjA0MBEGCWCGSAGG+EIBAQQEAwIAoDAfBgNVHSMEGDAWgBT84FToB/GV3jr3mcau+hUMbsQukjANBgkqhkiG9w0BAQQFAAOBgQBexv7o7mi3PLXadkmNP9LcIPmx93HGp0Kgyx1jIVMyNgsemeAwBM+MSlhMfcpbTrONwNjZYW8vJDSoi//yrZlVt9bJbs7MNYZVsyF1unsqaln4/vy6Uawfg8VUMk1U7jt8LYpo4YULU7UZHPYVUaSgVttImOHZIKi4hlPXBOhcUQ=="

		# nested vCard
		$suite | test-case "`$vcardTS[3].Name == Susan Thomas" { $vcardTS[3].Name } "Susan Thomas"
		
		# check version 4.0 result
		$suite | test-case "`$vcardTS[4].Name (vCard40)"			{ $vcardTS[4].Name } "vCard 4.0 Test Case"
		$suite | test-case "`$vcardTS[4].FormatType"				{ $vcardTS[4].FormatType } ([nl.nlsw.People.FormatType]::vCard40)
		$suite | test-case "`$vcardTS[4].Kind"						{ $vcardTS[4].Kind } "group"
		$suite | test-case "`$vcardTS[4]['kind']"					{ $vcardTS[4]['kind'].Value } "group"
		$suite | test-case "`$vcardTS[4]['source']"					{ $vcardTS[4]['source'].Uri } "ldap://ldap.example.com/cn=Babs%20Jensen,%20o=Babsco,%20c=US"
		$suite | test-case "`$vcardTS[4]['fn']"						{ $vcardTS[4]['fn'][0].Value } "vCard 4.0 Test Case"
		$suite | test-case "`$vcardTS[4]['n'].ToString()"			{ $vcardTS[4]['n'].ToString() } "Dr. John Philip Paul Stevenson Jr. M.D. A.C.P."
		$suite | test-case "`$vcardTS[4]['n'].GetAttribute('sort-as')" { $vcardTS[4]['n'].GetAttribute('sort-as') } "Stevenson,John"
		$suite | test-case "`$vcardTS[4]['nickname'][0][0]"			{ $vcardTS[4]['nickname'][0].Value[0] } "Jim"
		$suite | test-case "`$vcardTS[4]['nickname'][0][1]"			{ $vcardTS[4]['nickname'][0].Value[1] } "Jimmie"
		$suite | test-case "`$vcardTS[4]['nickname'][1]"			{ $vcardTS[4]['nickname'][1].Value } "Boss"
		$suite | test-case "`$vcardTS[4]['photo'].Uri"				{ $vcardTS[4]['photo'].Uri } "http://www.example.com/pub/photos/jqpublic.gif"
		$suite | test-case "`$vcardTS[4]['bday'].DateTime"			{ $vcardTS[4]['bday'].DateTime.ToString("yyyyMMddTHHmmssK") } "19531015T231000Z"
		$suite | test-case "`$vcardTS[4]['anniversary'].Value"		{ $vcardTS[4]['anniversary'].Value } "circa 1800"
		$suite | test-case "`$vcardTS[4]['gender'].GenderType"		{ $vcardTS[4]['gender'].GenderType } ([nl.nlsw.People.GenderType]::Other)
		$suite | test-case "`$vcardTS[4]['gender'].Identity"		{ $vcardTS[4]['gender'].Identity } "it's complicated"
		$suite | test-case "`$vcardTS[4]['adr'][0].GlobalPosition"	{ $vcardTS[4]['adr'][0].GlobalPosition } "geo:12.3457,78.910"
		$suite | test-case "`$vcardTS[4]['adr'][0].Label"			{ $vcardTS[4]['adr'][0].Label } "Mr. John Q. Public, Esq.`r`nMail Drop: TNE QB`r`n123 Main Street`r`nAny Town, CA  91921-1234`r`nU.S.A."
		$suite | test-case "`$vcardTS[4]['adr'][0].PostOfficeBox"	{ $vcardTS[4]['adr'][0].PostOfficeBox } ""
		$suite | test-case "`$vcardTS[4]['adr'][0].ExtendedAddress" { $vcardTS[4]['adr'][0].ExtendedAddress } ""
		$suite | test-case "`$vcardTS[4]['adr'][0].StreetAddress"	{ $vcardTS[4]['adr'][0].StreetAddress } "123 Main Street"
		$suite | test-case "`$vcardTS[4]['adr'][0].Locality"		{ $vcardTS[4]['adr'][0].Locality } "Any Town"
		$suite | test-case "`$vcardTS[4]['adr'][0].Region"			{ $vcardTS[4]['adr'][0].Region } "CA"
		$suite | test-case "`$vcardTS[4]['adr'][0].PostalCode"		{ $vcardTS[4]['adr'][0].PostalCode } "91921-1234"
		$suite | test-case "`$vcardTS[4]['adr'][0].CountryName"		{ $vcardTS[4]['adr'][0].CountryName } "U.S.A."
		$suite | test-case "`$vcardTS[4]['adr'][1].GlobalPosition"	{ $vcardTS[4]['adr'][1].GlobalPosition } "geo:52.503438,13.331812"
		$suite | test-case "`$vcardTS[4]['adr'][1].Label"			{ $vcardTS[4]['adr'][1].Label } "Kurfürstendamm 227-229`r`n10719 Berlin`r`nDeutschland"
		$suite | test-case "`$vcardTS[4]['adr'][1].PostOfficeBox"	{ $vcardTS[4]['adr'][1].PostOfficeBox } ""
		$suite | test-case "`$vcardTS[4]['adr'][1].ExtendedAddress" { $vcardTS[4]['adr'][1].ExtendedAddress } ""
		$suite | test-case "`$vcardTS[4]['adr'][1].StreetAddress"	{ $vcardTS[4]['adr'][1].StreetAddress } "Kurfürstendamm 227-229"
		$suite | test-case "`$vcardTS[4]['adr'][1].Locality"		{ $vcardTS[4]['adr'][1].Locality } "Berlin"
		$suite | test-case "`$vcardTS[4]['adr'][1].Region"			{ $vcardTS[4]['adr'][1].Region } ""
		$suite | test-case "`$vcardTS[4]['adr'][1].PostalCode"		{ $vcardTS[4]['adr'][1].PostalCode } "10719"
		$suite | test-case "`$vcardTS[4]['adr'][1].CountryName"		{ $vcardTS[4]['adr'][1].CountryName } "Deutschland"
		$suite | test-case "`$vcardTS[4]['tel'][0].Uri"				{ $vcardTS[4]['tel'][0].Uri } "tel:+1-555-555-5555;ext=5555"
		$suite | test-case "`$vcardTS[4]['tel'][1](.Uri)"			{ $vcardTS[4]['tel'][1].Uri } "tel:+49-30-887040"
		$suite | test-case "`$vcardTS[4]['email'][0].Uri"			{ $vcardTS[4]['email'][0].Uri } "mailto:jqpublic@xyz.example.com"
		$suite | test-case "`$vcardTS[4]['email'][1].Uri"			{ $vcardTS[4]['email'][1].Uri } "mailto:jane_doe@example.com"
		$suite | test-case "`$vcardTS[4]['impp'][0].Uri"			{ $vcardTS[4]['impp'][0].Uri } "xmpp:alice@example.com"
		$suite | test-case "`$vcardTS[4]['impp'][1].Uri"			{ $vcardTS[4]['impp'][1].Uri } "im:alice@example.com"
		$suite | test-case "`$vcardTS[4]['lang'][0]"				{ $vcardTS[4]['lang'][0].Value } "en"
		$suite | test-case "`$vcardTS[4]['tz'][0]"					{ $vcardTS[4]['tz'][0].Value } "America/New_York"
		$suite | test-case "`$vcardTS[4]['tz'][1]"					{ $vcardTS[4]['tz'][1].Value } "-0500"
		$suite | test-case "`$vcardTS[4]['geo'].Uri"				{ $vcardTS[4]['geo'].Uri } ([nl.nlsw.Identifiers.GeoUri]::New("geo:37.386013,-122.082932"))
		$suite | test-case "`$vcardTS[4]['title']"					{ $vcardTS[4]['title'].Value } "Research Scientist"
		$suite | test-case "`$vcardTS[4]['role']"					{ $vcardTS[4]['role'].Value } "Project Leader"
		$suite | test-case "`$vcardTS[4]['logo']"					{ $vcardTS[4]['logo'].Uri.Scheme } "data"
		$suite | test-case "`$vcardTS[4]['org'].OrganizationName"	{ $vcardTS[4]['org'].OrganizationName } "ABC, Inc."
		$suite | test-case "`$vcardTS[4]['org'].UnitName"			{ $vcardTS[4]['org'].OrganizationUnit } "North American Division"
		$suite | test-case "`$vcardTS[4]['org'].Value[2]"			{ $vcardTS[4]['org'].Value[2] } "Marketing"
		$suite | test-case "`$vcardTS[4]['member'].Uri"				{ $vcardTS[4]['member'].Uri } "mailto:jane_doe@example.com"
		$suite | test-case "`$vcardTS[4]['related'][0].Uri"			{ $vcardTS[4]['related'][0].Uri } "mailto:sthomas@host.com"
		$suite | test-case "`$vcardTS[4]['related'][1].Value"		{ $vcardTS[4]['related'][1].Value } "Please contact my assistant Jane Doe for any inquiries."
		$suite | test-case "`$vcardTS[4]['categories'].Value"		{ $vcardTS[4]['categories'].Value -join "," } "INTERNET,IETF,INDUSTRY,INFORMATION TECHNOLOGY"
		$suite | test-case "`$vcardTS[4]['note'].Value"				{ $vcardTS[4]['note'].Value } "This fax number is operational 0800 to 1715 EST, Mon-Fri."
		$suite | test-case "`$vcardTS[4]['prodid'].Uri"				{ $vcardTS[4]['prodid'].Uri } "urn:publicid:-:ONLINE+DIRECTORY:NONSGML+Version+1:EN"
		$suite | test-case "`$vcardTS[4]['rev'].DateTime"			{ $vcardTS[4]['rev'].DateTime.ToString("o") } "1995-10-31T22:27:10.0000000Z"
		$suite | test-case "`$vcardTS[4]['sound'].Uri"				{ $vcardTS[4]['sound'].Uri.ToString().StartsWith("data:audio/mp3;base64,SUQzAwAAAAAANVRDT04AAAANAAAASW5zdHJ1bWVudGFsVElUMgAAA") } $true
		$suite | test-case "`$vcardTS[4]['clientpidmap'].Value[0]"	{ $vcardTS[4]['clientpidmap'].Value[0] } "1"
		$suite | test-case "`$vcardTS[4]['clientpidmap'].Value[2]"	{ $vcardTS[4]['clientpidmap'].Value[1] } "urn:uuid:3df403f4-5924-4bb7-b077-3c711d9eb34b"
		$suite | test-case "`$vcardTS[4]['url'][0].Uri"				{ $vcardTS[4]['url'][0].Uri } "http://example.org/restaurant.french/~chezchic.html"
		$suite | test-case "`$vcardTS[4]['key'].Uri"				{ $vcardTS[4]['key'].Uri } "ftp://example.com/keys/jdoe"
		$suite | test-case "`$vcardTS[4]['fburl'].Uri"				{ $vcardTS[4]['fburl'].Uri } "ftp://example.com/busy/project-a.ifb"
		$suite | test-case "`$vcardTS[4]['caladruri'].Uri"			{ $vcardTS[4]['caladruri'].Uri } "mailto:janedoe@example.com"
		$suite | test-case "`$vcardTS[4]['caluri'].Uri"				{ $vcardTS[4]['caluri'].Uri } "http://cal.example.com/calA"
		$suite | test-case "`$vcardTS[4]['xml']"					{ $vcardTS[4]['xml'].Value } "<blockquote xmlns=`"http://www.w3.org/1999/xhtml`">To be or not to be, that is the question</blockquote>"
		$suite | test-case "`$vcardTS[4]['expertise'].Value"		{ $vcardTS[4]['expertise'].Value } "Chinese literature"
		$suite | test-case "`$vcardTS[4]['hobby'].Value"			{ $vcardTS[4]['hobby'].Value } "reading"
		$suite | test-case "`$vcardTS[4]['interest'].Value"			{ $vcardTS[4]['interest'].Value } "r&b music"
		$suite | test-case "`$vcardTS[4]['org-directory'].Uri"		{ $vcardTS[4]['org-directory'].Uri } "ldap://ldap.tech.example.com/o=Example%20Tech,ou=Engineering"
		$suite | test-case "`$vcardTS[4]['birthplace'].Value"		{ $vcardTS[4]['birthplace'].Value } "Babies'R'Us Hospital"
		$suite | test-case "`$vcardTS[4]['deathplace'].Value"		{ $vcardTS[4]['deathplace'].Uri } "http://example.com/ships/titanic.vcf"
		$suite | test-case "`$vcardTS[4]['deathdate'].Value"		{ $vcardTS[4]['deathdate'].DateTime.ToString("--MMdd") } "--0415"

		# @todo perform other tests

		
		# test Import-vCard with test.vcf
		$import = $( $suite | test-case "Import-vCard" { Import-vCard "$PSScriptRoot\test\test.vcf" } ([nl.nlsw.People.Directory]) -passThru ).output

		$firstFamily = $( $suite | test-case "get the first family" { $import["data:,F1"] } ([nl.nlsw.People.Person]) -passThru ).output
		$suite | test-case "`$firstFamily.Kind == Group" { $firstFamily.Kind } ([nl.nlsw.People.Kind]::Group)
		# test Export-vCard with the 3 versions
#		$export = $( $suite | test-case "Export-vCard" { $vcardTS | Export-vCard -verbose } $null -passThru ).output
		# test Export-vCard with the 3 versions
		$export = $( $suite | test-case "Export-vCard -format vCard21" { $vcardTS | Convert-vCard -format "vCard21" -verbose | Export-vCard -format "vCard21" -path "People.vCard21.Test.vcf" -verbose } ([System.IO.FileInfo]) -passThru ).output
		$export = $( $suite | test-case "Export-vCard -format vCard30" { $vcardTS | Convert-vCard -format "vCard30" -verbose | Export-vCard -format "vCard30" -path "People.vCard30.Test.vcf" -verbose } ([System.IO.FileInfo]) -passThru ).output
		$export = $( $suite | test-case "Export-vCard -format vCard40" { $vcardTS | Convert-vCard -format "vCard40" -verbose | Export-vCard -format "vCard40" -path "People.vCard40.Test.vcf" -verbose } ([System.IO.FileInfo]) -passThru ).output
		
		# test Convert-vCard with experimental and extended properties
		$vcardX = $( $suite | test-case "`$vcardX = Import-vCard (extended decoding)" { $ExperimentalvCardTestSource | Import-vCard -verbose } ([nl.nlsw.People.Directory]) -passThru ).output
		$suite | test-case "`$vcardX.Count == 2" { $vcardX.Count } 2
		$export = $( $suite | test-case "`$vcardX | Convert-vCard -format vCard40 | Export-vCard" { $vcardX | Convert-vCard -format "vCard40" -verbose | Export-vCard -format "vCard40" -path "People.X.Test.vcf" -verbose } ([System.IO.FileInfo]) -passThru ).output
		# check some results of the experimental transformation
		$suite | test-case "`$vcardX[0].GenderType == Male" { $vcardX[0].GenderType } "Male"
		$suite | test-case "`$vcardX[1].GenderType == Female" { $vcardX[1].GenderType } "Female"
		# also output an hCard
		$export = $( $suite | test-case "`$vcardX | Exportt-hCard -format vCard40" { $vcardX | Export-hCard -format "hCard1" -path "People.X.Test.xhtml" -verbose } ([System.IO.FileInfo]) -passThru ).output
		
		# processing output samples from Microsoft Windows Live Mail (vCard 2.1)
		$OutputEncoding = [System.Text.Encoding]::UTF8
		$mswinlive = $( $suite | test-case "Microsoft Windows Live Mail" { Import-vCard "$PSScriptRoot\test\MicrosoftLiveMail-output.vcf" } ([nl.nlsw.People.Directory]) -passThru ).output
		$suite | test-case "WLM.Count == 3" { $mswinlive.Count } 3
		$suite | test-case "WLM: quoted-printable in UID" { $mswinlive[0].ID } "http://localhost/kerkeninzuidland.nl/httpdocs/start.php?item=personen:CaseTest&action=vcard"
		$suite | test-case "WLM: quoted-printable in ADR" { $mswinlive[1].Properties['ADR'].StreetAddress } "Privé-adres 10"
		$suite | test-case "WLM: quoted-printable in NOTE" { $mswinlive[1].Properties['NOTE'].value } "€"

		# test simple import | export
		$expectedFileName = New-IncrementalFileName "People.Pietje_Puk.Test.vcf"
		$file = $( $suite | test-case "`"Pietje Puk`" | Import-vCard | Export-vCard" { "begin:vcard","version:4.0","fn:Pietje Puk","end:vcard" | Import-vCard -verbose | Export-vCard "People.{name}.Test.vcf" -verbose } ([System.IO.FileInfo]) -passThru ).output
		$suite | test-case "`$file == $expectedFileName" { $file.FullName } $expectedFileName
		
		# test Export-hCard
		$expectedFileName = New-IncrementalFileName "People.vCard40.Test.xhtml"
		$file = $( $suite | test-case "Export-hCard" { $vcardTS | Export-hCard "People.vCard40.Test.xhtml" -indent -verbose } ([System.IO.FileInfo]) -passThru ).output
		$suite | test-case "`$file == $expectedFileName" { $file.FullName } $expectedFileName
		
		# test Export-xCard
		$expectedFileName = New-IncrementalFileName "People.vCard40.Test.xml"
		$file = $( $suite | test-case "Export-xCard" { $vcardTS | Export-xCard "People.vCard40.Test.xml" -indent -verbose } ([System.IO.FileInfo]) -passThru ).output
		$suite | test-case "`$file == $expectedFileName" { $file.FullName } $expectedFileName

		# generate vCards and hCards for all Person.Kind, read via FilInfo object
		$allkinds = ""
		foreach ($kind in [System.Enum]::GetValues([nl.nlsw.People.Kind])) {
			$allkinds += @"
BEGIN:VCARD
VERSION:4.0
KIND:$kind
FN:vCard 4.0 Test Case Kind='$kind'
END:VCARD

"@
		}
		$expectedFileName = New-IncrementalFileName "People.AllKinds.Test.xhtml"
		$file = $( $suite | test-case "Export-vCard 'AllKinds'" { $allkinds | Import-vCard -verbose | Export-vCard "People.AllKinds.Test.vcf" -verbose } ([System.IO.FileInfo]) -passThru ).output
		$file = $( $suite | test-case "Export-hCard 'AllKinds'" { $file | Import-vCard -verbose | Export-hCard "People.AllKinds.Test.xhtml" -indent -verbose } ([System.IO.FileInfo]) -passThru ).output
		$suite | test-case "`$file == $expectedFileName" { $file.FullName } $expectedFileName
		
	}
	end {
		# return the tests in the pipeline
		$suite | Write-TestResult -passThru
	}
}