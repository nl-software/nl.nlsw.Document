#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.DotNet.psm1
# @date 2023-11-18
#requires -version 5

class DotNet {

	# NuGet repository of .NET packages
	static $nugetRepository = @{
		Name = "nuget.org";
		Provider = "NuGet";
		URL = " https://api.nuget.org/v3/index.json";
	}

	# static constructor
	static DotNet() {
		# run this only once to install required packages
		[DotNet]::Install()
	}

	# Function with dummy behavior that can be called to trigger
	# the one-time class construction.
	static [void] Check() {
	}

	# Make sure the NuGet PackageProvider is installed and the "nuget.org" PackageSource is registerd.
	static [void] Install() {
		$repo = [DotNet]::nugetRepository
		# check if the NuGet package provider is available
		$nugetPP = Get-PackageProvider $repo.Provider -ErrorAction SilentlyContinue
		if (!$nugetPP) {
			write-verbose ("{0,16} {1}" -f "installing","NuGet Package Provider for CurrentUser")
			# install the NuGet package provider for the current user
			Install-PackageProvider $repo.Provider -verbose -Scope CurrentUser
		}
		$nugetPS = Get-PackageSource $repo.Name
		if (!$nugetPS) {
			# register the NuGet package source
			Register-PackageSource -ProviderName $repo.Provider -Name $repo.Name -Location $repo.URL -verbose
		}
	}
}

<#
.SYNOPSIS
 Builds a combined PowerShell module and .NET package.

.DESCRIPTION
 Builds a combined PowerShell module and .NET package. The resulting package
 can be published in a PowerShell Gallery (PowerShellGet) repository,
 as well as in a .NET (NuGet) repository.

 Building a PowerShell Module for publication is done by the Publish-Module
 command of PowerShellGet. This command not only builds the package, but
 publishes it as well in a target repository.

 In order to be able to post-process the package, a file system repository
 is required. You can use an existing repository, or let the function create
 a temporary one.

 Note, that the repository needs to contain dependent modules, apart from the
 ones declared in the module manifest's ExternalModuleDependencies list.
 When creating multiple (dependent) packages, feed them in the right order into
 the function.

 The Publish-Module function packages all files in the module folder into the
 module package, without using the FileList in the module manifest.
 This function therefore copies the module manifest and the files listed in the
 FileList into a temporary folder. Publish-Module is called on this temporary
 folder, so the set of files in the package is fully controlled.

 If the PowerShell module contains a C# project for building a .NET library,
 the C# project is built. The resulting library assemblies are copied into the
 'lib' folder, as required for NuGet. For this process the dotnet SDK is
 expected to be available.

 After creation of the PowerShell module package, a few NuGet metadata elements
 that are not (yet) supported by PowerShellGet can be updated in the package
 nuspec manifest.

.PARAMETER Path
 The name of the module manifest file or of the folder containing the module to package.
 May contain wildcards.

.PARAMETER Repository
 The name of the PowerShellGet repository to publish the module into. This must be
 a repository on the local file system. If the repository does not exist, a local
 folder $RepositoryFolder is created in the current directory and temporarily
 registered as the named repository.

 Note that the repository needs to have a flat, i.e. non-hierarchical, structure.
 This means you cannot use `nuget add` to add packages to this repository.

 By default, a repository called 'LocalPSGet' is used.

.PARAMETER RepositoryFolder
 The name of the folder that is created in the current directory as repository
 folder, in case the specified $Repository does not exist.
 By default, the folder is '.LocalPSGet'.

.PARAMETER Force
 Overwrite the package if it already exists.

.PARAMETER MetadataElement
 One or more .nuspec metadata elements that PowerShellGet not (yet) supports
 in the module manifest, but are needed (or nice to have) in the NuGet
 specification file in the package.

 The contents of these elements that are present in the module manifest
 'PrivateData.PSData' section, is copied to the corresponding element in
 the nuspec file in the package.

.INPUTS
 String
 System.IO.FileSystemInfo

.OUTPUTS
 System.IO.FileInfo

.LINK
 https://learn.microsoft.com/en-us/powershell/scripting/gallery/how-to/publishing-packages/publishing-a-package

.LINK
 https://learn.microsoft.com/en-us/nuget/create-packages/overview-and-workflow

.EXAMPLE
 $packageFile = Build-DotNetPowerShellPackage "C:\data\projects\nl.nlsw.Document"

 Builds the NuGet package file nl.nlsw.Document.<version>.nupkg that contains both
 a PowerShell module as well as a .NET assembly package.
#>
function Build-DotNetPowerShellPackage {
	[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
	[OutputType([System.IO.FileInfo])]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Justification="Is approved in PS6", Scope='Function')]
	param (
		[Parameter(Mandatory=$false, Position=0, ValueFromPipeline = $true,
			HelpMessage="Enter the name of the module folder or manifest file to process")]
		[SupportsWildcards()]
		[object]$Path = ".",

		[Parameter(Mandatory=$false)]
		[string]$Repository = "LocalPSGet",

		[Parameter(Mandatory=$false)]
		[string]$RepositoryFolder = ".LocalPSGet",

		[Parameter(Mandatory=$false)]
		[switch]$Force,

		[Parameter(Mandatory=$false)]
		[string[]]$MetadataElement = @('icon','readme','repository')
	)
	begin {
		$workFolder = [System.IO.Path]::Combine($env:TEMP,'pspackage')
		$manifestExt = ".psd1"
		$packageExt = ".nupkg"
		$temporaryRepo = $false
		if ($Repository) {
			# check the existence and usability of the repository
			$repo = Get-PSRepository -Name $Repository -ErrorAction SilentlyContinue
			if (!$repo) {
				# create the repo in the current file system location
				# create a temporary folder for packaging (PowerShellGet does not have a separate Package-Module command :-(
				$repoFolder = New-Item -ItemType Directory -Force -Path "./" -Name $RepositoryFolder
				# temporarily register the 'repository'
				Register-PSRepository -Name $Repository -SourceLocation $repoFolder.FullName -PublishLocation $repoFolder.FullName -InstallationPolicy Trusted | write-verbose
				$temporaryRepo = $true
				$repo = Get-PSRepository -Name $Repository -ErrorAction SilentlyContinue
			}
			$publishLocation = [uri]$repo.PublishLocation
			if (!$publishLocation.IsFile) {
				throw [ArgumentException]::new("repository '$Repository' does not have a PublishLocation on the file system: '$publishLocation'","Repository")
			}
			$repoFolder = get-item $publishLocation.LocalPath
		}
		else {
			throw [ArgumentException]::new("please specify a PowerShellGet repository to use","Repository")
		}

		# .NET 4.5 required for using ZipFile and friends
		Add-Type -assembly "System.IO.Compression"
		Add-Type -assembly "System.IO.Compression.FileSystem"
	}
	process {
		$Path |  foreach-object {
			# collect and filter .psd1 files
			$item = $_
			if ($item -is [string]) {
				$item = get-item $item
			}
			if ($item -is [System.IO.DirectoryInfo]) {
				$item.GetFiles("*" + $manifestExt)
			}
			elseif (($item -is [System.IO.FileInfo]) -and ($item.Extension -eq $manifestExt)) {
				$item
			}
		} | where-object { $_ } | foreach-object {
			$item = $_
			if ($PSCmdlet.ShouldProcess($item.FullName)) {
				Push-Location $item.Directory
				try {
					# get the package name (without terminating '.')
					$packageName = [System.IO.Path]::ChangeExtension($item.Name,"").TrimEnd('.')
					$psd = Import-PowerShellDataFile $item.FullName
					# determine the version of the package
					$packageVersion = $psd.ModuleVersion
					if ($psd.PrivateData.PSData.Prerelease) {
						$packageVersion += '-'
						$packageVersion += $psd.PrivateData.PSData.Prerelease
					}
					# determine the NuGet package name
					$packageVersionName = $packageName + '.' + $packageVersion
					# the package being build
					$packageFile = [System.IO.FileInfo]::new([System.IO.Path]::Combine($repoFolder.FullName,$packageVersionName+$packageExt))
					if ($packageFile.Exists -and !$Force)  {
						# the package already exists
						Write-Error (("package '$packageFile' already exists; specify -Force to overwrite"))
						return
					}
					# check if a .csproj is present, if so, build that project
					$csproj = [System.IO.FileInfo]::new([System.IO.Path]::ChangeExtension($item.FullName,".csproj"))
					if ($csproj.Exists) {
						$dllname = [System.IO.Path]::ChangeExtension($item.Name,".dll")
						if (!(Get-Command dotnet)) {
							throw [InvalidOperationException]::new(("missing 'dotnet.exe' to build the C# project {0}" -f $csproj))
						}
						write-verbose ("{0,16} {1}" -f "building",$csproj)
						dotnet build | write-verbose
						# @see https://github.com/dotnet/runtime/blob/main/docs/design/features/host-error-codes.md
						if ($LASTEXITCODE -eq 0) {
							# success, get the built dll(s) in the build folder
							$dlls = Get-ChildItem -Recurse -File -Include $dllname -Path "bin/Debug/"
							# copy dll to lib folder
							foreach ($dll in $dlls) {
								# create the platform folder in the lib folder
								$platform = New-Item -ItemType Directory -Force -Path "lib/" -Name $dll.Directory.Name
								if ($platform) {
									$libdll = Copy-Item $dll.FullName $platform.FullName -PassThru
									write-verbose ("{0,16} {1}" -f "built",$libdll.FullName)
								}
							}
						}
						else {
							throw [InvalidOperationException]::new(("dotnet build error of C# project {0}" -f $csproj))
						}
					}
					# create a copy of the folders and files to package, based on the FileList in the manifest
					# create a temporary folder for packaging
					$packaging = New-Item -ItemType Directory -Force -Path $workFolder -Name $packageName
					foreach ($file in $psd.FileList) {
						$relativePath = [System.IO.Path]::GetDirectoryName($file)
						# create the target folder
						$pfolder = New-Item -ItemType Directory -Force -Path $packaging.FullName -Name $relativePath
						$pfile = Copy-Item $file $pfolder.FullName -PassThru
						write-verbose ("{0,16} {1}" -f "including",$pfile.FullName)
					}
					# make sure that the manifest itself is also packaged (locate in the root of the package)
					$pfile = Copy-Item $item.FullName $packaging.FullName -PassThru
					write-verbose ("{0,16} {1}" -f "including",$pfile.FullName)
					# remove the existing package
					if ($packageFile.Exists) {
						write-verbose ("{0,16} {1}" -f "removing",$packageFile.FullName)
						$packageFile.Delete()
					}
					# now, package (and publish) the PowerShell Module
					write-verbose ("{0,16} {1}" -f "packaging",$packaging.FullName)
					# do not add automatic tags
					Publish-Module -Path $pfile.DirectoryName -Repository $Repository -SkipAutomaticTags
					# check status of published package
					$packageFile.Refresh()
					if ($packageFile.Exists) {
						# check if we need to update the nuspec file with NuGet features not covered by PowerShellGet
						$update = $false
						if ($MetadataElement) {
							foreach ($element in $MetadataElement) {
								if ($psd.PrivateData.PSData.$element) {
									$update = $true
									break
								}
							}
						}
						if ($update) {
							# define for some elements the preferred location in the metadata element
							$successors = @{ 'icon'='p:iconUrl'; 'readme'='p:releaseNotes'; 'repository'='p:projectUrl'; }
							write-verbose ("{0,16} {1}" -f "updating",$packageFile.FullName)
							$zipFile = [System.IO.Compression.ZipFile]::Open($packageFile.FullName, [System.IO.Compression.ZipArchiveMode]::Update)
							try {
								$nuspecFileName = $packageName + '.nuspec'
								$nuspecEntry = $zipFile.GetEntry($nuspecFileName)
								if (!$nuspecEntry) {
									throw [InvalidOperationException]::new(("file '$nuspecFileName' not found in '$packageFile'"))
								}
								write-verbose ("{0,16} {1}:{2}" -f "reading",$packageFile.FullName,$nuspecFileName)
								# read the nuspec as XmlDocument
								$nuspecStream = $nuspecEntry.Open()
								$reader = [System.IO.StreamReader]::new($nuspecStream)
								$nuspec = [xml]$reader.ReadToEnd();
								$nsm = [System.Xml.XmlNamespaceManager]::new($nuspec.NameTable)
								# read the (default) namespace from the document (it differs per NuGet run)
								$nuspecNs = $nuspec.DocumentElement.GetNamespaceOfPrefix('')
								if ($nuspecNs) {
									$nsm.AddNamespace('p',$nuspecNs)
								}
								$reader.Dispose()
								# write-verbose ($nuspec.OuterXml.ToString())
								# update the nuspec
								foreach ($element in $MetadataElement) {
									if ($psd.PrivateData.PSData.$element -and ($null -eq $nuspec.package.metadata.SelectSingleNode("p:$element",$nsm))) {
										$node = $nuspec.CreateElement($element,$nuspecNs)
										$value = $psd.PrivateData.PSData.$element
										if ($value -is [hashtable]) {
											foreach ($kvp in $value.GetEnumerator()) {
												if (![string]::IsNullOrEmpty($kvp.Value)) {
													$node.SetAttribute($kvp.Key,$kvp.Value)
													write-verbose (("{0,16} {1}.{2} = {3}" -f "metadata",$node.Name,$kvp.Key,$kvp.Value))
												}
											}
										}
										else {
											# string element
											$node.InnerText = $psd.PrivateData.PSData.$element
											write-verbose (("{0,16} {1} = {2}" -f "metadata",$node.Name,$node.InnerText))
										}
										$successor = $successors[$element]
										# put the readme before the releaseNotes if that exists, otherwise append at the metadata
										$nextSibling = if ($successor) { $nuspec.package.metadata.SelectSingleNode($successor,$nsm) } else { $null }
										$nuspec.package.metadata.InsertBefore($node, $nextSibling) | out-null
									}
								}
								write-verbose ("{0,16} {1}:{2}" -f "writing",$packageFile.FullName,$nuspecFileName)
								# write the nuspec back to the zipfile
								$nuspecStream = $nuspecEntry.Open()
								$nuspec.Save($nuspecStream)
								$nuspecStream.Dispose()
							}
							finally {
								$zipFile.Dispose()
							}
						}
					}
				}
				finally {
					# cleanup the temporary folder
					if ($packaging) {
						Remove-Item $packaging -Recurse
					}
					Pop-Location
				}
				$packageFile.Refresh()
				if ($packageFile.Exists) {
					write-verbose ("{0,16} {1}" -f "built",$packageFile.FullName)
					write-output $packageFile
				}
			}
		}
	}
	end {
		if ($temporaryRepo) {
			# unregister the (temporary) repository
			Unregister-PSRepository -Name $Repository | write-verbose
		}
		# If($?){ # only execute if the function was successful.
		if (Test-path $workFolder) {
			write-verbose ("{0,16} {1}" -f "removing",$workFolder)
			Remove-Item $workFolder
		}
	}
}

<#
.SYNOPSIS
 Get a .NET package for using the included DLL in a PowerShell session.

.DESCRIPTION
 Using a .NET DLL that is available as NuGet package on nuget.org requires
 installation of the package and importing the assembly into the PowerShell
 session (with Add-Type).

 This operation tests if the package is installed. If not, it is installed
 for the CurrentUser from nuget.org. It returns the installed package.

.PARAMETER Name
 Specifies then name of the package. May be input via the pipeline.
 Use pipeline notation if you want to specify multiple packages.

.PARAMETER RequiredVersion
 Specifies the exact version of the package to find.

.PARAMETER MinimumVersion
 Specifies the maximum package version that you want to find.

.PARAMETER MaximumVersion
 Specifies the minimum package version that you want to find. If a higher
 version is available, that version is returned.

.PARAMETER SkipDependencies
 Skips the installation of software dependencies.

.INPUTS
 System.String

.OUTPUTS
 Microsoft.PackageManagement.Packaging.SoftwareIdentity#GetPackage

 Note that the Source property of the returned object contains the
 path to the locally installed package.

.LINK
 https://learn.microsoft.com/en-us/powershell/module/packagemanagement/get-package

.NOTES
 This function requires PowerShellGet 2.2.5 with PackageManagement 1.4.8.1, or better.
 If it needs to install a package, it also requires the NuGet Package Provider
 and the "nuget.org" Package Source, which  in turn will also be installed
 and registered if not present already.

 This function is a helper for solving the problem:
 https://stackoverflow.com/questions/39257572/loading-assemblies-from-nuget-packages

#>
function Get-DotNetPackage {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline = $true)]
		[Alias("PackageName")]
		[string]$Name,

		[Parameter(Mandatory=$false)][Alias("Version")]
		[string]$RequiredVersion,

		[Parameter(Mandatory=$false)]
		[string]$MinimumVersion,

		[Parameter(Mandatory=$false)]
		[string]$MaximumVersion,

		[Parameter(Mandatory=$false)]
		[switch]$SkipDependencies
	)
	begin {
	}
	process {
		$Name | where-object { ![string]::IsNullOrEmpty($_) } | foreach-object {
			$packageName = $_
			# create the arguments for the Get-Package function
			$attrs = [System.Collections.Generic.Dictionary[[string],[object]]]::new($PSBoundParameters)
			$attrs.Remove("SkipDependencies") | Out-Null
			# check the presence of the package
			$package = Get-Package @attrs -ErrorAction SilentlyContinue
			if (!$package) {
				# make the user aware of the installation action
				$PSBoundParameters["Verbose"] = $true
				write-verbose ("{0,16} {1}" -f "installing",$packageName)
				# First check if the NuGet package provider is available and the "nuget.org" source is registered.
				[DotNet]::Check()
				# install the package (specify the source to avoid exception in case of multiple sources)
				$source = [DotNet]::nugetRepository
				$package = Install-Package @PSBoundParameters -Scope CurrentUser -Source $source.Name -ProviderName $source.Provider
				# Install-Package returns the package location in .Payload.Directories[0]. { .Location, .Name }
				# we need to do a Get-Package, to get the package location in the .Source property.
				$package = Get-Package @attrs
			}
			write-output $package
		}
	}
	end {
	}
}

<#
.SYNOPSIS
 Import a .NET class library in a PowerShell session.

.DESCRIPTION
 Using a .NET DLL that is available as NuGet package on nuget.org requires
 installation of the package and importing the class library assembly into
 the PowerShell session (with Add-Type).

 This operation performs this operation. By default, it assumes that the
 name of the library (assembly) equals the name of the package.
 Specify the PackageName if that differs from the library assembly name.

.PARAMETER Name
 Specifies the class library name. This must be the name of the
 .NET library assembly (.DLL) file and the NuGet package as well.

 May be input via the pipeline.

.PARAMETER PackageName
 Specifies the name of the NuGet package that contains the class library.
 By default, the package name equals the Name parameter.

.PARAMETER RequiredVersion
 Specifies the exact version of the package to find.

.PARAMETER MinimumVersion
 Specifies the maximum package version that you want to find.

.PARAMETER MaximumVersion
 Specifies the minimum package version that you want to find. If a higher
 version is available, that version is returned.

.PARAMETER SkipDependencies
 Skips the installation of software dependencies.

.PARAMETER TargetFramework
 The .NET framework of the class library to import.
 By default, "netstandard2.0".

.INPUTS
 System.String

.OUTPUTS
 System.IO.FileInfo - of the loaded DLL

.LINK
 https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/add-type

.NOTES
 This function uses Get-DotNetPackage if needed.
#>
function Import-DotNetLibrary {
	[CmdletBinding()]
	[OutputType([System.IO.FileInfo])]
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline = $true)]
		[string]$Name,

		[Parameter(Mandatory=$false)]
		[string]$PackageName,

		[Parameter(Mandatory=$false)][Alias("Version")]
		[string]$RequiredVersion,

		[Parameter(Mandatory=$false)]
		[string]$MinimumVersion,

		[Parameter(Mandatory=$false)]
		[string]$MaximumVersion,

		[Parameter(Mandatory=$false)]
		[switch]$SkipDependencies,

		[Parameter(Mandatory=$false)]
		[string]$TargetFramework = "netstandard2.0"
	)
	begin {
	}
	process {
		$Name | where-object { ![string]::IsNullOrEmpty($_) } | foreach-object {
			$assemblyName = $_
			# check the presence of the assembly in the session (
			$assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
			if (!($assemblyName -in $assemblies.GetName().Name)) {
				# create the arguments for the Get-DotNetPackage function
				$attrs = [System.Collections.Generic.Dictionary[[string],[object]]]::new($PSBoundParameters)
				if ($PSBoundParameters["PackageName"]) {
					$attrs.Remove("Name") | Out-Null
				}
				$attrs.Remove("TargetFramework") | Out-Null
				# Second, check the presence of the package, and install if needed
				$package = Get-DotNetPackage @attrs
				# Get the dll for the target framework
				$packageFile = get-item $package.Source
				$packageFolder = $packageFile.DirectoryName
				$assemblyFile = get-item ("$packageFolder/lib/$TargetFramework/$assemblyName.dll")
				write-verbose ("{0,16} {1}" -f "loading",$assemblyFile)
				Add-Type -Path $assemblyFile
				write-output $assemblyFile
			}
		}
	}
	end {
	}
}



Export-ModuleMember -Function *