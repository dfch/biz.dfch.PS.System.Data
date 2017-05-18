function Invoke-CmdText 
{
	[CmdletBinding(
		SupportsShouldProcess = $false
	)]
	Param
	(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $ConnectionString
		,
		[Parameter(Mandatory = $true, Position = 1)]
		[string] $Query
		,
		[Parameter(Mandatory = $false)]
		[ValidateSet('SqlClient', 'ODBC', 'OleDb')]
		[String] $DataProvider = 'SqlClient'
		,
		[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty', 'DataSet', 'Table')]
		[alias("ReturnFormat")]
		[string] $As = 'default'
	)

	try 
	{
		$fReturn = $false;
		$OutputParameter = $null;

		switch ($DataProvider) 
		{ 
			'SqlClient' 
			{
				$Connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString);
				$Command = New-Object System.Data.SqlClient.SqlCommand($Query, $Connection);
				$Command.CommandTimeout = $ConnectionTimeout;
				$Connection.Open();

				$DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter($Command);
				break;
			}
			'ODBC' 
			{
				$Connection = New-Object System.Data.Odbc.OdbcConnection($ConnectionString);
				$Command = New-Object System.Data.Odbc.OdbcCommand($Query, $Connection);
				$Command.CommandTimeout = $ConnectionTimeout;
				$Connection.Open();

				$DataAdapter = New-Object System.Data.Odbc.OdbcDataAdapter($Command);
				break;
			}
			'OleDb' 
			{
				$Connection = New-Object System.Data.OleDb.OleDbConnection($ConnectionString);
				$Command = New-Object System.Data.OleDb.OleDbCommand($Query, $Connection);
				$Command.CommandTimeout = $ConnectionTimeout;
				$Connection.Open();

				$DataAdapter = New-Object System.Data.OleDb.OleDbDataAdapter($Command);
				break;
			}
			default {
				throw [System.NotImplementedException] "Handling for data provider '$DataProvider' not implemented."
			}
		}
		
		$DataSet = New-Object System.Data.DataSet;
		$DataSetRows = $DataAdapter.Fill($DataSet);

		if($DataSetRows -gt 0) 
		{
			$Table = $DataSet.Tables[0];
			switch($As) 
			{
				'DataSet' 
				{ 
					$r = $DataSet; 
				}
				'Table' 
				{ 
					$r = $Table; $DataSet.Dispose(); 
				}
				Default 
				{ 
					$r = New-Object System.Collections.ArrayList($DataSetRows);
					$Columns = $DataSet.Tables[0].Columns.ColumnName;
					foreach($TableRow in $Table) 
					{
						$rRow = @{}
						foreach($Column in $Columns) 
						{
							$rRow.Add($Column, $TableRow[$Column]);
						}
						$null = $r.Add($rRow);
					}
					$DataSet.Dispose();
				}
			}
		}

		switch($As) 
		{
			'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
			'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
			'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
			'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
			Default { $OutputParameter = $r; }
		}
		$fReturn = $true;
		return $OutputParameter;
	}
	catch 
	{
		throw($_);
	}
	finally 
	{
		# Clean up
		if($Command) 
		{
			$Command.Dispose();
			Remove-Variable Command;
		}
		if($Connection -And $Connection.State -eq 'Open') 
		{
			$Connection.Close();
		}
		if($Connection) 
		{
			$Connection.Dispose();
			Remove-Variable Connection;
		}
	}
} # function
if($MyInvocation.ScriptName) { Export-ModuleMember -Function Invoke-CmdText; } 

#
# Copyright 2014-2017 d-fens GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
