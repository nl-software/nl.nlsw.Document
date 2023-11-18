# nl.nlsw.Document changelog

## Release nl.nlsw.Document-1.2.0

### Added
- nl.nlsw.DotNet.ps1 with support for using .NET assemblies
- nl.nlsw.Excel.ps1 for access to Excel documents
- nl.nlsw.Document.png icon

### Fixed
- Get-ValidFileName() and New-IncrementalFileName replace SPACE although a valid filename char
  - PS [string](char[]) performs a -join i.s.o. a construction: fix [string]::new(char[])
- Import-Ini: key-value regex superfluous '?'

## Release 2022-10-24 nl.nlsw.Document-1.1.0

### Changed
- Version number conform [Semantic Versioning 2.0.0]. However,
  restricting to SemVer 1.0.0 for [PowerShell Gallery Prerelease Module] compatibility.
- Prepared for first release on PowerShell Gallery.

## References

- These release notes are loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

---
[PowerShell Gallery Prerelease Module]: https://learn.microsoft.com/en-us/powershell/scripting/gallery/concepts/module-prerelease-support
[Semantic Versioning 2.0.0]: <https://semver.org/> "semver.org"

