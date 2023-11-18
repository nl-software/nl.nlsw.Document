#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.SQLite.psm1
# @date 2023-11-14
#requires -version 5

class SQLite {
	static [string] $PackageName = "Stub.System.Data.SQLite.Core.NetStandard"
	static [string] $PackageVersion = "1.0"

	# static constructor
	static SQLite() {
		# run this only once
		[SQLite]::Install([SQLite]::PackageName,[SQLite]::PackageVersion)
	}

	# Function with dummy behavior that can be called to trigger
	# the one-time class construction.
	static [void] Check() {
	}

	# Make sure the System.Data.SQLite .NET Standard 2.0 library is loaded
	# @see https://stackoverflow.com/questions/39257572/loading-assemblies-from-nuget-packages
	# @see https://stackoverflow.com/questions/69118045/sqlkata-with-sqlite-minimal-example-powershell/69126680
	static [void] Install([string]$packageName,[string]$packageVersion) {
		$assemblyName = "System.Data.SQLite"
		# check the presence of the assembly in the session (
		$assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
		if (!($assemblyName -in $assemblies.GetName().Name)) {
			# check the presence of the SQLite package
			$sqlite = Get-Package $packageName -RequiredVersion $packageVersion -ErrorAction SilentlyContinue
			if (!$sqlite) {
				# install the package
				$sqlite = Get-DotNetPackage $packageName -RequiredVersion $packageVersion
				# make the platform-specific InterOp dll available for Win32 and Win64
				if ([System.Environment]::OSVersion.Platform -eq $([System.PlatformID]::Win32NT)) {
					$sqliteNupkg = get-item $sqlite.Source
					foreach ($platform in "64","86") {
						# make sure the InterOp.dll is in the location that the managed dll will look for
						$destFile = [System.IO.FileInfo]::new((Join-Path $($sqliteNupkg.DirectoryName) "lib/netstandard2.0/x$($platform)/SQLite.Interop.dll"))
						if (!$destFile.Exists) {
							if (!$destFile.Directory.Exists) {
								# make sure the target folder exists
								$destFile.Directory.Create()
								$destFile.Directory.Refresh()
							}
							# copy the InterOp.dll to the location that the managed dll will look for
							$interop = get-item (Join-Path $($sqliteNupkg.DirectoryName) "runtimes/win-x$($platform)/native/SQLite.Interop.dll")
							Copy-Item $interop.FullName $destFile.FullName
							$destFile.Refresh()
							write-verbose ("{0,16} {1}" -f "copied",$destFile)
						}
					}
				}
				else {
					throw [InvalidOperationException]::new(("please install the $packageName package manually on operating system {0}" -f $env:OS))
				}
			}
			# Get the NetStandard2.0 dll
			$sqlitePackageFile = get-item $sqlite.Source
			$sqlitedll = get-item (Join-Path $sqlitePackageFile.DirectoryName "lib/netstandard2.0/System.Data.SQLite.dll")
			Add-Type -Path $sqlitedll
		}
	}
}

<#
.SYNOPSIS
 Get an SQLite database content as System.Data.DataSet.

.DESCRIPTION
 Get data from an SQLite database, using the System.Data.SQLite .NET library.

.PARAMETER Path
 The file name of the SQLite file(s) to process. May contain wildcards,
 and may be input via the pipeline.

.PARAMETER TableName
 The name of the table to get. When left empty (default), all tables are returned.

.INPUTS
 System.String

.OUTPUTS
 System.Data.DataSet

.LINK
 https://system.data.sqlite.org/

.NOTES
 This function requires the System.Data.SQLite .NET assembly.
 It will be automatically installed if not present already.
 This installation requires the NuGet Package Provider, which
 in turn will also be installed if not present already.
#>
function Get-SQLiteDataSet {
	[CmdletBinding()]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'TableName', Justification="false positive")]
	param(
		[Parameter(Mandatory=$true, Position=0, ValueFromPipeline = $true)]
		[SupportsWildcards()]
		[string]$Path,

		[Parameter(Mandatory=$false, Position=1)]
		[Alias("table")]
		[string]$TableName
	)
	begin {
		[SQLite]::Check()

		function GetDataTable {
			param([System.Data.SQLite.SQLiteConnection]$con, [string]$sql)
			$table = [System.Data.DataTable]::new()
			try {
				$cmd = [System.Data.SQLite.SQLiteCommand]::new($sql, $con);
				$reader = $cmd.ExecuteReader();
				$table.Load($reader);
			}
			finally {
				if ($cmd) {
					$cmd.Dispose()
				}
			}
			return ,$table
		}
	}
	process {
		$Path | get-item | where-object { $_ -is [System.IO.FileInfo] } | foreach-object {
			$file = $_
			$dataset = [System.Data.DataSet]::new()
			write-verbose ("{0,16} {1}" -f "reading",$file.FullName)
			try {
				# https://social.technet.microsoft.com/wiki/contents/articles/30562.powershell-accessing-sqlite-databases.aspx
				# https://stackoverflow.com/questions/20256043/is-there-easy-method-to-read-all-tables-from-sqlite-database-to-dataset-object
				$con = [System.Data.SQLite.SQLiteConnection]::new(("Data Source={0}" -f $file.FullName))
				$con.Open()
				if ($TableName) {
					$table = GetDataTable $con ("SELECT * FROM '{0}'" -f $TableName)
					$dataset.Tables.Add($table)
					write-verbose ("{0,16} {1} ({2} rows)" -f "table",$TableName,$table.Rows.Count)
				}
				else {
					# read the names of the tables
					$namesTable = GetDataTable $con "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY 1"
					$names = [System.Collections.Generic.List[string]]::new();
					foreach ($row in $namesTable.Rows) {
						$tableName = $row.ItemArray[0].ToString()
						$names.Add($tableName);
						$table = GetDataTable $con ("SELECT * FROM '{0}'" -f $tableName)
						$dataset.Tables.Add($table)
						write-verbose ("{0,16} {1} ({2} rows)" -f $names.Count,$tableName,$table.Rows.Count)
					}
				}
			}
			#catch {
			#	# something went wrong ??
			#	Write-Error $_.Exception.Message
			#}
			finally {
				if ($con) {
					$con.Close();
				}
			}

			# Return the results as a set
			return ,$dataset
		}
	}
	end {
	}
}

<#
.SYNOPSIS
 Execute one or more SQL commands on an SQLite database.

.DESCRIPTION
 Edit an SQLite database by executing one or more SQL commands.

 This functions uses the System.Data.SQLite .NET library.

.PARAMETER Path
 The file name of the SQLite database file to process.

.PARAMETER Command
 The SQL command to invoke. May be pipelined.

.PARAMETER DataSet
 The dataset to store the results in.

.PARAMETER NonQuery
 Return no result data of the executed commands.

.PARAMETER SingleTransaction
 Automatically will execute the commands in a single transaction.

.INPUTS
 System.String
 System.String[]

.OUTPUTS
 System.Data.DataRow
 System.Data.DataTable
 System.Data.DataSet

.LINK
 https://system.data.sqlite.org/
 https://zetcode.com/csharp/sqlite/

.NOTES
 This function requires the System.Data.SQLite .NET assembly.
 It will be automatically installed if not present already.
 This installation requires the NuGet Package Provider, which
 in turn will also be installed if not present already.
#>
function Invoke-SQLiteCommand {
	[CmdletBinding()]
	[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'NonQuery', Justification="false positive")]
	param(
		[Parameter(Mandatory=$true, Position=0)]
		[Alias("database")]
		[string]$Path,

		[Parameter(Mandatory=$true, Position=1, ValueFromPipeline = $true)]
		[Alias("sql")]
		[string[]]$Command,

		[Parameter(Mandatory=$false, Position=2)]
		[System.Data.DataSet]$DataSet,

		[Parameter(Mandatory=$false)]
		[switch]$NonQuery,

		[Parameter(Mandatory=$false)]
		[switch]$SingleTransaction
	)
	begin {
		[SQLite]::Check()

		$file = Get-Item $Path
		$con = [System.Data.SQLite.SQLiteConnection]::new(("Data Source={0}" -f $file.FullName))
		$con.Open()
		$cmd = [System.Data.SQLite.SQLiteCommand]::new($con);
		write-verbose ("{0,16} {1}" -f "opening",$file.FullName)
		#$dataset = [System.Data.DataSet]::new()
		$transaction = if ($SingleTransaction) { $con.BeginTransaction() } else { $null }
	}
	process {
		try {
			$Command | where-object { $_ -is [string] } | foreach-object {
				$cmd.CommandText = $_
				write-verbose ("{0,16} {1}" -f "executing",$cmd.CommandText)
				if ($NonQuery) {
					$numberOfRows = $cmd.ExecuteNonQuery();
					write-verbose ("{0,16} rows updated" -f $numberOfRows)
				}
				else {
					$reader = $cmd.ExecuteReader();
					$table = [System.Data.DataTable]::new()
					$table.Load($reader)
					if ($DataSet) {
						$DataSet.Tables.Add($table)
					}
					else {
						$table
					}
				}
			}
		}
		catch {
			if ($transaction) {
				$transaction.Dispose()
				$transaction = $null
			}
			throw
		}
		if ($cmd) {
			$cmd.Dispose()
			$cmd = $null
		}
		if ($con) {
			write-verbose ("{0,16} {1}" -f "closing",$file.FullName)
			$con.Close();
			$con.Dispose();
			$con = $null
		}
		if ($DataSet) {
			$DataSet.Dispose()
			$DataSet = $null
		}
	}
	end {
		if ($transaction) {
			write-verbose ("{0,16} {1}" -f "committing",$file.FullName)
			$transaction.Commit()
		}
		if ($cmd) {
			$cmd.Dispose()
		}
		if ($con) {
			write-verbose ("{0,16} {1}" -f "closing",$file.FullName)
			$con.Close();
			$con.Dispose();
		}
		if ($DataSet) {
			Write-Output $DataSet -NoEnumerate
		}
	}
}

Export-ModuleMember -Function *