function Invoke-OdbcCmd {
<#
.SYNOPSIS
Runs a script containing statements from the languages and commands supported by the .NET System.Data.Odbc classes and methods.


.DESCRIPTION
Runs a script containing statements from the languages and commands supported by the .NET System.Data.Odbc classes and methods.


.OUTPUTS
The output of the Cmdlet depends on the QueryType parameter. By default an array of hashtables is returned. If you want to get the raw data, you can also specify a DataSet or a Table (array DataRows).


.INPUTS
This Cmdlet lets you execute queries and commands against a database using the ODBC provider.


.EXAMPLE
# Get all system table names from default database with username and password. Result is a DataSet. 
Note: You have to manually Dispose() this data set after use.

PS > Invoke-OdbcCmd -ServerInstance '.\SQLEXPRESS' -Database 'Arbitrary' 'SELECT name, type_desc FROM [sys].[tables]' -Driver '{SQL Server}' -Username 'Arbitrary' -Password 'P@ssw0rd' -As DataSet;



.EXAMPLE
# Get all system table names from default database with Windows authentication. Result is a JSON string. 

PS > Invoke-OdbcCmd -ServerInstance '.\SQLEXPRESS' -Database 'Arbitrary' 'SELECT TOP 3 name, type_desc FROM [sys].[tables]' -Driver '{SQL Server}' -Username 'Arbitrary' -Password 'P@ssw0rd' -As json-pretty;
[
  {
    "name":  "spt_fallback_db",
    "type_desc":  "USER_TABLE"
  },
  {
    "name":  "spt_fallback_dev",
    "type_desc":  "USER_TABLE"
  },
  {
    "name":  "spt_fallback_usg",
    "type_desc":  "USER_TABLE"
  }
]


.EXAMPLE
# Login with SQL Credentials and get version information from named SQL instance.

PS > Invoke-OdbcCmd -ServerInstance '.\SQLEXPRESS' -Database 'Arbitrary' 'SELECT name FROM [sys].[tables]' -Driver '{SQL Server}' -Username 'Arbitrary' -Password 'P@ssw0rd';


.EXAMPLE
# Get identity from access database (.mdb or .accdb).

PS > Invoke-OdbcCmd -Dbq 'C:\arbitrary-database.mdb' -Driver '{Microsoft Access Driver (*.mdb, *.accdb)}' "Select @@Identity";


.EXAMPLE
# Login with credentials and get identity from .mdb.

PS > Invoke-OdbcCmd -Dbq 'C:\arbitrary-database.mdb' -Driver '{Microsoft Access Driver (*.mdb, *.accdb)}' "Select @@Identity" -Username 'Arbitrary' -Password 'P@ssw0rd';


.LINK
Online Version: http://dfch.biz/biz/dfch/PS/System/Data/Invoke-OdbcCmd/


.NOTES
When returning a DataSet you have to manually dispose it after use (see QueryType option).

Requires module 'biz.dfch.PS.System.Logging'.
Requires module 'biz.dfch.PS.System.Utilities'.


#>
[CmdletBinding(
    SupportsShouldProcess = $true
	,
    ConfirmImpact = 'Low'
	,
	DefaultParameterSetName = 'name-plain'
	,
	HelpURI = 'http://dfch.biz/biz/dfch/PS/System/Data/Invoke-OdbcCmd/'
)]
Param
(
	# Specifies the database server and optionally a named instance.
	[Parameter(Mandatory = $true, ParameterSetName = 'name-plain')]
	[Parameter(Mandatory = $true, ParameterSetName = 'name-secure')]
	[string] $ServerInstance
	,
	# Specifies the database to connect to.
	[Parameter(Mandatory = $false, ParameterSetName = 'name-plain')]
	[Parameter(Mandatory = $false, ParameterSetName = 'name-secure')]
	[string] $Database = [String]::Empty
	,
	# Specifies the md file to connect to.
	[Parameter(Mandatory = $true, ParameterSetName = 'dbq-plain')]
	[Parameter(Mandatory = $true, ParameterSetName = 'dbq-secure')]
	[string] $Dbq = [String]::Empty
	,
	[Parameter(Mandatory = $true, ParameterSetName = 'string-name')]
	[Parameter(Mandatory = $true, ParameterSetName = 'string-secure')]
	[string] $ConnectionString
	,
	[Parameter(Mandatory = $true, Position = 0)]
	[Alias('SqlQuery')]
	[string] $Query
	,
	[Parameter(Mandatory = $true, ParameterSetName = 'dbq-plain')]
	[Parameter(Mandatory = $true, ParameterSetName = 'dbq-secure')]
	[Parameter(Mandatory = $true, ParameterSetName = 'name-plain')]
	[Parameter(Mandatory = $true, ParameterSetName = 'name-secure')]
	[string] $Driver
	,
	# This parameter (in seconds) overrides the default Odbc 
	# Command connection timeout.
	[Parameter(Mandatory = $false)]
	[int] $ConnectionTimeout = 45
	,
	# SQL username with which to perform login.
	[Parameter(Mandatory = $false, ParameterSetName = 'dbq-plain')]
	[Parameter(Mandatory = $false, ParameterSetName = 'name-plain')]
	[Parameter(Mandatory = $false, ParameterSetName = 'string-plain')]
	[string] $Username
	,
	# SQL plaintext password with which to perform login.
	[Parameter(Mandatory = $false, ParameterSetName = 'dbq-plain')]
	[Parameter(Mandatory = $false, ParameterSetName = 'name-plain')]
	[Parameter(Mandatory = $false, ParameterSetName = 'string-plain')]
	[string] $Password
	,
	# Encrypted SQL credentials as [System.Management.Automation.PSCredential] 
	# with which to perform login.
	[Parameter(Mandatory = $true, ParameterSetName = 'dbq-secure')]
	[Parameter(Mandatory = $true, ParameterSetName = 'name-secure')]
	[Parameter(Mandatory = $true, ParameterSetName = 'string-secure')]
	[PSCredential] $Credential
	,
	# Specifies the type of query to perform. 
	# Currently only 'Text' and 'default' are supported.
	[ValidateSet('default', 'Text', 'TableDirect', 'StoredProcedure')]
	[Parameter(Mandatory = $false)]
	[string] $QueryType = 'default'
	,
	# Lets you specify the return format of the SQL query. 
	# Default is an (array of) hashtable.
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty', 'DataSet', 'Table')]
	[alias("ReturnFormat")]
	[string] $As = 'default'
)

$datBegin = [datetime]::Now;
[string] $fn = $MyInvocation.MyCommand.Name;
Log-Debug -fn $fn -msg ("CALL. PSCmdlet.ParameterSetName '{0}'." -f $PSCmdlet.ParameterSetName) -fac 1;
# Default test variable for checking function response codes.
[Boolean] $fReturn = $false;
# Return values are always and only returned via OutputParameter.
$OutputParameter = $null;

try 
{
	# Parameter validation
	# N/A

	# Build connection string depending on input parameters
	if($PSCmdlet.ParameterSetName.StartsWith('name-')) 
	{
		$builder = [System.Data.Odbc.OdbcConnectionStringBuilder]::new();
		$builder.Add('Server', $ServerInstance);
		if($PSBoundParameters.ContainsKey('Database')) 
		{
			$builder.Add('Database', $Database);
		}
		$builder.Driver = $Driver;
		$builder.Add('Uid', $Username);
		$builder.Add('Pwd', $Password);
	} 
	elseif ($PsCmdlet.ParameterSetName.StartsWith('dbq-'))
	{
		$builder = [System.Data.Odbc.OdbcConnectionStringBuilder]::new();
		$builder.Add('Dbq', $Dbq);
		$builder.Driver = $Driver;
	}
	else
	{
		$builder = [System.Data.Odbc.OdbcConnectionStringBuilder]::new($ConnectionString);
	}
	
	if($PSCmdlet.ParameterSetName.EndsWith('-secure')) 
	{
		$builder.Add('Uid', $Credential.Username);
		$builder.Add('Pwd', $Credential.GetNetworkCredential().Password);
	}
	
	if($PSCmdlet.ParameterSetName.EndsWith('-plain')) 
	{
		$builder.Add('Uid', $Username);
		$builder.Add('Pwd',  $Password);
	} 
	else 
	{
		# Clear out sensitive information in case it was passed in from the caller
		if($builder.ContainsKey('Uid')) { $null = $builder.Remove('Uid'); }
		if($builder.ContainsKey('Pwd')) { $null = $builder.Remove('Pwd'); }
	}
	$ConnectionString = $builder.ToString();

	if(!$PSCmdlet.ShouldProcess($Query)) 
	{
		$fReturn = $false;
		$OutputParameter = $null;
		throw($gotoSuccess);
	}

	$Result = $null;
	if($QueryType -eq 'Default') 
	{ 
		$QueryType = 'Text'; 
	}
	switch($QueryType) 
	{
		'Text' 
		{
			$Result = Invoke-CmdText -ConnectionString $ConnectionString -Query $Query -DataProvider ODBC -As $As;
		}
		default 
		{
			$msg = "This QueryType has not been implemented: '{0}'" -f $QueryType;
			Log-Error $fn $msg;
			$e = New-CustomErrorRecord -m $msg -cat NotImplemented -o $QueryType; 
			throw($gotoError);
		}
	}
	$fReturn = $true;
	$OutputParameter = $Result;
}
catch 
{
	if($gotoSuccess -eq $_.Exception.Message) 
	{
		$fReturn = $true;
	}
	else 
	{
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception -is [System.Net.WebException]) 
		{
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Exception.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		}
		else 
		{
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) 
			{
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} 
			elseif($gotoFailure -eq $_.Exception.Message) 
			{ 
				Write-Verbose ("$fn`n$ErrorText"); 
			} 
			else 
			{
				throw($_);
			}
		}
		$fReturn = $false;
		$OutputParameter = $null;
	}
}
finally 
{
	# Clean up
	# N/A

	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
}
return $OutputParameter;

} # function

if($MyInvocation.ScriptName) { Export-ModuleMember -Function Invoke-OdbcCmd; } 

#
# Copyright 2017 d-fens GmbH
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
