#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.DotNet.psm1
# @date 2023-11-13
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
				write-host ("{0,16} {1}" -f "installing",$packageName)
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

 This operation performs this operation. It assumes that the name of the
 library equals the name of the assembly and of the package.

.PARAMETER Name
 Specifies the class library name. This must be the name of the
 .NET library assembly (.DLL) file and the NuGet package as well.

 May be input via the pipeline.

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
	param(
		[Parameter(Mandatory=$true, ValueFromPipeline = $true)]
		[string]$Name,

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
			$packageName = $_
			# check the presence of the assembly in the session (
			$assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
			if (!($packageName -in $assemblies.GetName().Name)) {
				# create the arguments for the Get-DotNetPackage function
				$attrs = [System.Collections.Generic.Dictionary[[string],[object]]]::new($PSBoundParameters)
				$attrs.Remove("TargetFramework") | Out-Null
				# Second, check the presence of the package, and install if needed
				$package = Get-DotNetPackage @attrs
				# Get the dll for the target framework
				$packageFile = get-item $package.Source
				$packageDll = get-item (Join-Path $packageFile.DirectoryName "lib/$TargetFramework/$packageName.dll")
				write-host ("{0,16} {1}" -f "loading",$packageDll)
				Add-Type -Path $packageDll
				write-output $packageDll
			}
		}
	}
	end {
	}
}



Export-ModuleMember -Function *