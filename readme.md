# nl.nlsw.Document

The nl.nlsw.Document module supports PowerShell and .NET processing of documents.

The module contains C# classes and PowerShell functions to support specific document
type processing by PowerShell modules.

The module includes the following submodules:

- *nl.nlsw.Document* - A .NET *utility* class and PowerShell *utility* module.
- *nl.nlsw.DotNet* - Functions to import .NET assemblies and create PowerShell/.NET packages.
- *nl.nlsw.EPUB* - Functions to produce EPUB documents.
- *nl.nlsw.Excel* - Functions to read Microsoft Excel documents.
- *nl.nlsw.Feed* - Functions to read Atom or RSS web feed documents.
- *nl.nlsw.FileSystem* - PowerShell utility functions for file and filesytem operations.
- *nl.nlsw.Items* - Classes and functions process generalized ItemObject documents.
- *nl.nlsw.Identifiers* - Classes that represent various Uniform Resource Identifiers (URIs).
- *nl.nlsw.JSON* - Functions for JSON processing.
- *nl.nlsw.SQLite* - Functions for SQLite database access via [System.Data.SQLite].
- *nl.nlsw.XmlDocument* - Functions for constructing, and updating XmlDocument objects.

## Installation

You can install the module in your own user environment from the [PowerShell Gallery](https://www.powershellgallery.com/packages/nl.nlsw.Document/):

```powershell
Install-Module -Name nl.nlsw.Document -Scope CurrentUser
```

## Usage

For usage examples, use the PowerShell Get-Help function for the individual commands:

```powershell
Get-Help <command>
```

To list the available commands in the module:

```powershell
Get-Command -Module nl.nlsw.Document
```

### Known Issues

This module contains commands that use [PowerShell Approved Verbs] like `Build`, that were approved
after Windows PowerShell version 5, and therefore will trigger a warning when the module is
imported in your Windows PowerShell session.

## Documentation

A little documentation on the module is included and available via:

```powershell
Get-Help about_nl.nlsw.Document
```

## Downloading the Source Code

You can clone the repository:

```sh
git clone https://github.com/nl-software/nl.nlsw.Document.git
```

## Dependencies

- Microsoft .NET Framework (.NET Standard 2.0)
- Windows PowerShell 5.1
- [PowerShellGet 2.2 and PackageManagement 1.4]

The following submodules require additional .NET packages. The packages will be
automatically installed in the user environment when needed.
- nl.nlsw.Excel
  - `ExcelDataReader.dll` from *[ExcelDataReader 3.6]*.
  - `ExcelDataReader.DataSet.dll` from *[ExcelDataReader.DataSet 3.6]*.

- nl.nlsw.SQLite
  - `System.Data.SQLite.dll` from *[Stub.System.Data.SQLite.Core.NetStandard 1.0]*.
    Note that this is a .NET Standard 2.0 package.

For running the unit test of the module, you require:

- PowerShell module https://github.com/nl-software/nl.nlsw.TestSuite

```powershell
Install-Module -Name nl.nlsw.TestSuite -Scope CurrentUser
```

## Languages

This module can be used in two ways:

- as (Windows) PowerShell module.

- as PowerShell / C# package compiled with the latest .NET SDK.
  A **NETstandard2.0** assembly is included.

## Legal and Licensing

nl.nlsw.Document is licensed under the [EUPL-1.2 license][].

[EUPL-1.2 license]: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12
[ExcelDataReader 3.6]: https://www.nuget.org/packages/ExcelDataReader
[ExcelDataReader.DataSet 3.6]: https://www.nuget.org/packages/ExcelDataReader.DataSet
[PowerShell Approved Verbs]: https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands
[PowerShellGet 2.2 and PackageManagement 1.4]: https://learn.microsoft.com/en-us/powershell/gallery/powershellget/update-powershell-51
[System.Data.SQLite]: https://system.data.sqlite.org/
[Stub.System.Data.SQLite.Core.NetStandard 1.0]: https://www.nuget.org/packages/Stub.System.Data.SQLite.Core.NetStandard
