#	__ _ ____ _  _ _    _ ____ ____   ____ ____ ____ ___ _  _ ____ ____ ____
#	| \| |=== |/\| |___ | |--- |===   ==== [__] |---  |  |/\| |--| |--< |===
#
# @file nl.nlsw.Excel.psm1
# @date 2023-11-14
#requires -version 5

class Excel {
	# https://www.nuget.org/packages/ExcelDataReader.DataSet
	static [string] $DataSetPackage = "ExcelDataReader.DataSet"
	static [string] $DataSetVersion = "3.6"
	# https://www.nuget.org/packages/ExcelDataReader
	static [string] $DataReaderPackage = "ExcelDataReader"
	static [string] $DataReaderVersion = "3.6"

	# static constructor
	static Excel() {
		# run this only once
		[Excel]::Install([Excel]::DataReaderPackage,[Excel]::DataReaderVersion)
		[Excel]::Install([Excel]::DataSetPackage,[Excel]::DataSetVersion)
	}

	# Function with dummy behavior that can be called to trigger
	# the one-time class construction.
	static [void] Check() {
	}

	# Make sure the .NET Standard 2.0 library of the specified package is loaded
	# @param $packageName the name of the package (and the assembly!)
	# @param $packageVersion the required version of the package
	# @see https://stackoverflow.com/questions/39257572/loading-assemblies-from-nuget-packages
	static [void] Install([string]$packageName,[string]$packageVersion) {
		Import-DotNetLibrary -Name $packageName -MinimumVersion $packageVersion -SkipDependencies
	}
}

<#
.SYNOPSIS
 Get a Microsoft Excel document sheet's content.

.DESCRIPTION
 Get data from an Excel worksheet, using a COM interface to Microsoft Excel.

 The first row in the sheet is the header of the table (@todo make option)

 The rows of the sheet are returned as PSObject objects, similar to the
 output of the ConvertFrom-CSV command.

.PARAMETER Path
 The file name of the Excel file to process.

.PARAMETER WorksheetName
 The name of the worksheet to get.

.OUTPUTS
 System.Management.Automation.PSObject

.LINK
 https://devblogs.microsoft.com/scripting/beat-the-auditors-be-one-step-ahead-with-powershell/

.NOTES
 @author Ernst van der Pols, edited from internet-source
#>
function Get-ExcelData {
	[CmdletBinding(DefaultParameterSetName='Worksheet')]
	param(
		[Parameter(Mandatory=$true, Position=0)]
		[string]$Path,

		[Parameter(Position=1, ParameterSetName='Worksheet')]
		[Alias("sheet")]
		[string]$WorksheetName = 'Sheet1'
	)
	begin {
		# @see https://devblogs.microsoft.com/scripting/beat-the-auditors-be-one-step-ahead-with-powershell/
		$excel = new-object -com Excel.Application
		$excel.Visible = $true

		$Path = resolve-path $Path
		#switch ($pscmdlet.ParameterSetName) {
		#	'Worksheet' {
		#		$Query = 'SELECT * FROM [{0}$]' -f $WorksheetName
		#		break
		#	}
		#}
		#write-verbose "Get-ExcelData from $Path sheet $Query"
	}
	process {
		$file = get-item $Path
		write-verbose ("{0,16} {1}" -f "processing",$file)
		if ($file.Extension -in @('.xls','.xlsm')) {
			# voor xlsm heb je ProtectedViews.Open nodig(?)
			$pvw = $excel.ProtectedViewWindows.open($file)
			$wb = $pvw.Workbook
		}
		else {
			$wb = $excel.Workbooks.open($file)
		}

		# @see https://docs.microsoft.com/en-us/office/vba/api/excel.xlcelltype
		$xlCellTypeLastCell = 11

		write-verbose ("{0,16} {1}" -f "protected",$file)
		write-verbose ("{0,16} {1}" -f "sheets",$wb.sheets.count)
		for ($i = 1; $i -le $wb.sheets.count; $i++) {
			$sh = $wb.Sheets.Item($i)
			$sh.Activate()
			# determine the UsedRange
			$usedRange = $sh.UsedRange.SpecialCells($xlCellTypeLastCell)
			$maxRow = $usedRange.Row
			$maxColumn = $usedRange.Column
			write-verbose ("{0,16} {1}" -f $i,$sh.Name)
			if ($sh.Name -eq $WorksheetName) {
				# read the first row (= header), look where the contents end (at least within 1000 columns)
				$col = 1
				$row = 1
				$header = @()
				for ($col = 1; $col -le $maxColumn; $col++) {
					$value = [string]$sh.Cells.Item($row, $col).Value2
					if ([string]::IsNullOrEmpty($value)) {
						break;
					}
					$header += $value.Trim()
					write-verbose ("{0,16} {1}" -f "column",$value)
				}
				# extract all non-empty rows as objects
				for ($row = 2; $row -le $maxRow; $row++) {
					$item = [ordered]@{}
					for ($col = 1; $col -le $header.length; $col++) {
						$cell = [string]$sh.Cells.Item($row, $col).Value2
						$item.Add($header[$col - 1],$cell)
					}
					write-verbose ("{0,16} {1}" -f $row,$item.Name)
					write-output [psobject]$item
					if ([string]::IsNullOrEmpty($item[$header[0]])) {
						# empty line (first column): end of data
						break
					}
				}
			}
		}
		$excel.Workbooks.Close()
	}
	end {
		# close excel
		$excel.quit()
		# Remove all com related variables
		# @see https://devblogs.microsoft.com/scripting/beat-the-auditors-be-one-step-ahead-with-powershell/
		Get-Variable -Scope script `
		| Where-Object {$_.Value.pstypenames -contains ‘System.__ComObject’} `
		| Remove-Variable -Verbose
		[GC]::Collect() #.net garbage collection
		[GC]::WaitForPendingFinalizers() #more .net garbage collection
	}
}

<#
.SYNOPSIS
 Get a Microsoft Excel document sheet's content as System.Data.DataTable.

.DESCRIPTION
 Import data from an Excel worksheet, using an OLE database connection to Microsoft Excel.

 Note that you need to have Microsoft Excel installed.

.PARAMETER Path
 The file name of the Excel file to import data from.

.PARAMETER WorksheetName
 The name of the worksheet to get.

.PARAMETER Query
 Geeks can enter an SQL query in stead of a sheet name.

.OUTPUTS
 System.Data.DataTable

.NOTES
 @author Ernst van der Pols, edited from internet-source
#>
function Get-ExcelDataTable {
	[CmdletBinding(DefaultParameterSetName='Worksheet')]
	param(
		[Parameter(Mandatory=$true, Position=0)]
		[String]$Path,

		[Parameter(Position=1, ParameterSetName='Worksheet')]
		[Alias("sheet")]
		[String]$WorksheetName = 'Sheet1',

		[Parameter(Position=1, ParameterSetName='Query')]
		[String]$Query = 'SELECT * FROM [Sheet1$]'
	)
	begin {
		$Path = resolve-path $Path
		switch ($pscmdlet.ParameterSetName) {
			'Worksheet' {
				$Query = 'SELECT * FROM [{0}$]' -f $WorksheetName
				break
			}
			'Query' {
				# Make sure the query is in the correct syntax (e.g. 'SELECT * FROM [SheetName$]')
				$Pattern = '.*from\b\s*(?<Table>\w+).*'
				if($Query -match $Pattern) {
					$Query = $Query -replace $Matches.Table, ('[{0}$]' -f $Matches.Table)
				}
				break
			}
		}
		write-verbose "Get-ExcelDataTable from $Path sheet $Query"
	}
	process {
		# Create the scriptblock to run in a job
		$JobCode = {
			param($Path, $Query)

			# Check if the file is XLS or XLSX
			if ((Get-Item -Path $Path).Extension -eq 'xls') {
				$Provider = 'Microsoft.Jet.OLEDB.4.0'
				$ExtendedProperties = 'Excel 8.0;HDR=YES;IMEX=1'
			} else {
				$Provider = 'Microsoft.ACE.OLEDB.12.0'
				$ExtendedProperties = 'Excel 12.0;HDR=YES'
			}

			# Build the connection string and connection object
			$ConnectionString = 'Provider={0};Data Source={1};Extended Properties="{2}"' -f $Provider, $Path, $ExtendedProperties
			$Connection = New-Object System.Data.OleDb.OleDbConnection $ConnectionString

			try {
				# Open the connection to the file, and fill the datatable
				$Connection.Open()
				$Adapter = New-Object -TypeName System.Data.OleDb.OleDbDataAdapter $Query, $Connection
				$DataTable = New-Object System.Data.DataTable
				$Adapter.Fill($DataTable) | Out-Null
			}
			catch {
				# something went wrong ??
				Write-Error $_.Exception.Message
			}
			finally {
				# Close the connection
				if ($Connection.State -eq 'Open') {
					$Connection.Close()
				}
			}

			# Return the results as an array
			Write-Output $DataTable -NoEnumerate
		}

		# Run the code in a 32bit job, since the provider is 32bit only
		$job = Start-Job $JobCode -RunAs32 -ArgumentList $Path, $Query
		$job | Wait-Job | Receive-Job
		Remove-Job $job
	}
	end {
	}
}

<#
.SYNOPSIS
 Get a Microsoft Excel document's content as System.Data.DataSet.

.DESCRIPTION
 Import data from an Excel document, using the ExcelDataReader .NET library.

 Note that you do not need to have Microsoft Excel installed.

 Note currently ExcelDataReader version 3 is used.

.PARAMETER Path
 The file name of the Excel file(s) to import. May contain wildcards,
 and may be input via the pipeline.

.PARAMETER IsFirstRowAsColumnNames
 Treat the first row in each sheet as the table header row,
 containing the column names.

.INPUTS
 System.String

.OUTPUTS
 System.Data.DataSet

.LINK
 https://github.com/ExcelDataReader/ExcelDataReader

.LINK
 https://www.nuget.org/packages/ExcelDataReader.DataSet
#>
function Import-ExcelDataSet {
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true, Position=0, ValueFromPipeline = $true)]
		[SupportsWildcards()]
		[string]$Path,

		[Parameter(Mandatory=$false)]
		[bool]$IsFirstRowAsColumnNames = $true
	)
	begin {
		[Excel]::Check()
	}
	process {
		$Path | get-item | where-object { $_ -is [System.IO.FileInfo] } | foreach-object {
			$file = $_
			$ExcelReader = $null;
			$dataset = $null
			write-verbose ("{0,16} {1}" -f "reading",$file.FullName)
			try {
				# create the reader
				if ($file.Extension -eq ".xls") {
					$ExcelReader = [ExcelDataReader.ExcelReaderFactory]::CreateBinaryReader($file.OpenRead());
				}
				elseif ($file.Extension -in @(".xlsx", ".xlsm")) {
					$ExcelReader = [ExcelDataReader.ExcelReaderFactory]::CreateOpenXmlReader($file.OpenRead());
				}
				else {
					write-error ("unsupported file extension of file '{0}'" -f $file.FullName)
					return
				}

				# all tables have a row header (or not), and if so, only include columns with a column name (trimming of excess Excel)
				$dataTableConfiguration = [ExcelDataReader.ExcelDataTableConfiguration]::new();
				$dataTableConfiguration.UseHeaderRow = $IsFirstRowAsColumnNames
				if ($IsFirstRowAsColumnNames) {
					$dataTableConfiguration.FilterColumn = {
						param([ExcelDataReader.IExcelDataReader]$reader,[int]$columnOrdinal)
						# check if a column name is present, if so, include this column and return true
						return !$reader.IsDBNull($columnOrdinal)
					}
				}
				$excelDataSetConfig = [ExcelDataReader.ExcelDataSetConfiguration]::new();
				$excelDataSetConfig.ConfigureDataTable = {
					param([ExcelDataReader.IExcelDataReader]$reader)
					return $dataTableConfiguration
				}
				# note that in PowerShell you must call extension methods as static method.
				$dataset = [ExcelDataReader.ExcelDataReaderExtensions]::AsDataSet($ExcelReader, $excelDataSetConfig);
				$ExcelReader.Close();
			}
			catch {
				# something went wrong ??
				Write-Error $_.Exception.Message
			}
			finally {
				if ($ExcelReader -and !$ExcelReader.IsClosed) {
					$ExcelReader.Close();
				}
			}
			# Return the results as a set
			Write-Output $dataset -NoEnumerate
		}
	}
	end {
	}
}

Export-ModuleMember -Function *