# nl.nlsw.Document

The nl.nlsw.Document module supports PowerShell and .NET processing of documents.

The module contains C# classes and PowerShell functions to support specific document
type processing by PowerShell modules.

The module includes the following submodules:

- *nl.nlsw.Document* - A .NET *utility* class and PowerShell *utility* module.
- *nl.nlsw.EPUB* - Functions to produce EPUB documents.
- *nl.nlsw.Excel* - Functions to read Microsoft Excel documents.
- *nl.nlsw.Feed* - Functions to read Atom or RSS web feed documents.
- *nl.nlsw.FileSystem* - PowerShell utility functions for file and filesytem operations.
- *nl.nlsw.Items* - Classes and functions process generalized ItemObject documents.
- *nl.nlsw.Identifiers* - Classes that represent various Uniform Resource Identifiers (URIs).
- *nl.nlsw.JSON* - Functions for JSON processing.
- *nl.nlsw.SQLite* - Functions for SQLite database access via [System.Data.SQLite](https://system.data.sqlite.org/).
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

For running the unit test of the module, you require:

- PowerShell module https://github.com/nl-software/nl.nlsw.TestSuite

```powershell
Install-Module -Name nl.nlsw.TestSuite -Scope CurrentUser
```

- The nl.nlsw.Excel module requires the `ExcelDataReader.dll`
  and the `ExcelDataReader.DataSet.dll`.
  The module will automatically install the *ExcelDataReader*
  library package in the user environment, when needed.

- The nl.nlsw.SQLite module requires the `System.Data.SQLite.dll`.
  The module will automatically install the *System.Data.SQLite .NET Standard 2.0*
  library package in the user environment, when needed.

## Languages

This module can be used in two ways:

- as (Windows) PowerShell module.

- as PowerShell / C# package compiled with the latest .NET SDK.
  A **NETstandard2.0** assembly is included.

## Legal and Licensing

nl.nlsw.Document is licensed under the [EUPL-1.2 license][].

[EUPL-1.2 license]: https://joinup.ec.europa.eu/collection/eupl/eupl-text-eupl-12