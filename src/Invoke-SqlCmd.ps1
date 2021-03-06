function Invoke-SqlCmd {
<#
.SYNOPSIS
Runs a script containing statements from the languages (Transact-SQL and XQuery) and commands supported by the .NET System.Data.SqlClient classes and methods.


.DESCRIPTION
Runs a script containing statements from the languages (Transact-SQL and XQuery) and commands supported by the .NET System.Data.SqlClient classes and methods.

Basically provides the same options as the Microsoft SQL Server 'Invoke-SqlCmd' Cmdlet. You can set an alias to replace the Microsoft Cmdlet with this Cmdlet.

With this Cmdlet you can also login to LocalDB database instances when you specify it via a ConnectionString. See examples for details.


.OUTPUTS
The output of the Cmdlet depends on the QueryType parameter. By default an array of hashtables is returned. If you want to get the raw data, you can also specify a DataSet or a Table (array DataRows).


.INPUTS
This Cmdlets basically lets you perform the same actions as the 'Invoke-SqlCmd' Cmdlet from the Microsoft 'SqlServerCmdletSnapin100' PSSnapin, but provides additional options. In its basic version the interface is compatible with the Microsoft SQL Server Cmdlet.


.EXAMPLE
# Get all system table names from default database with Windows authentication. Result is an array of hashtables.

PS > Invoke-SqlCmd -ServerInstance '.\SQLEXPRESS' 'SELECT name, type_desc FROM [sys].[tables]' -IntegratedSecurity;



.EXAMPLE
# Get all system table names from default database with Windows authentication. Result is a SQL DataSet. 
Note: You have to manually Dispose() this data set after use.

PS > Invoke-SqlCmd -ServerInstance '.\SQLEXPRESS' 'SELECT name, type_desc FROM [sys].[tables]' -IntegratedSecurity -As DataSet;



.EXAMPLE
# Get all system table names from default database with Windows authentication. Result is a JSON string. 

PS > Invoke-SqlCmd -ServerInstance '.\SQLEXPRESS' 'SELECT TOP 3 name, type_desc FROM [sys].[tables]' -IntegratedSecurity -As json-pretty;
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

PS > Invoke-SqlCmd -ServerInstance '.\SQLEXPRESS' 'SELECT name FROM [sys].[tables]' -IntegratedSecurity;


.EXAMPLE
# Login with SQL Credentials and get version information from named SQL instance.

PS > Invoke-SqlCmd -ServerInstance '.\SQLEXPRESS' -Username 'Edgar.Schnittenfittich' -Password 'P@ssw0rd' 'SELECT @@VERSION';


.EXAMPLE
# Login with integrated security to named SQL instance 'SERVER1\SQLEXPRESS' by using a connection string but override specified credentials.

PS > Invoke-SqlCmd -ConnectionString 'Data Source=SERVER1\SQLEXPRESS;Initial Catalog=CumulusCfg;Integrated Security=False;User ID=sa;Password=P@ssw0rd' 'SELECT @@VERSION' -IntegratedSecurity;


.EXAMPLE
# Login with integrated security to a (LocalDB) file database via a ConnectionString.

PS > Invoke-SqlCmd -ConnectionString 'Data Source=(LocalDB)\v11.0;AttachDbFilename="C:\ApplicationDatabase.mdf";Integrated Security=True;Connect Timeout=30' 'SELECT @@VERSION AS [Version]' -IntegratedSecurity;
Name    Value
----    -----
Version Microsoft SQL Server 2012 (SP1) - 11.0.3000.0 (X64) ...


.LINK
Online Version: http://dfch.biz/biz/dfch/PS/System/Data/Invoke-SqlCmd/


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
	DefaultParameterSetName = 'name-integrated'
	,
	HelpURI = 'http://dfch.biz/biz/dfch/PS/System/Data/Invoke-SqlCmd/'
)]
Param
(
	# Specifies the SQL Server and optionally a named instance.
	[Parameter(Mandatory = $true, ParameterSetName = 'name-plain')]
	[Parameter(Mandatory = $true, ParameterSetName = 'name-secure')]
	[Parameter(Mandatory = $true, ParameterSetName = 'name-integrated')]
	[string] $ServerInstance
	,
	# Specifies the SQL Server database to connect to.
	[Parameter(Mandatory = $false, ParameterSetName = 'name-plain')]
	[Parameter(Mandatory = $false, ParameterSetName = 'name-secure')]
	[Parameter(Mandatory = $false, ParameterSetName = 'name-integrated')]
	[string] $Database = [String]::Empty
	,
	[Parameter(Mandatory = $true, ParameterSetName = 'string-name')]
	[Parameter(Mandatory = $true, ParameterSetName = 'string-secure')]
	[Parameter(Mandatory = $true, ParameterSetName = 'string-integrated')]
	[string] $ConnectionString
	,
	[Parameter(Mandatory = $true, Position = 0)]
	[Alias('SqlQuery')]
	[string] $Query
	,
	# This parameter (in seconds) overrides the default SqlClient 
	# Command connection timeout.
	[Parameter(Mandatory = $false)]
	[int] $ConnectionTimeout = 45
	,
	# SQL username with which to perform login.
	[Parameter(Mandatory = $false, ParameterSetName = 'name-plain')]
	[Parameter(Mandatory = $false, ParameterSetName = 'string-plain')]
	[string] $Username
	,
	# SQL plaintext password with which to perform login.
	[Parameter(Mandatory = $false, ParameterSetName = 'name-plain')]
	[Parameter(Mandatory = $false, ParameterSetName = 'string-plain')]
	[string] $Password
	,
	# Encrypted SQL credentials as [System.Management.Automation.PSCredential] 
	# with which to perform login.
	[Parameter(Mandatory = $false, ParameterSetName = 'name-secure')]
	[Parameter(Mandatory = $false, ParameterSetName = 'string-secure')]
	[PSCredential] $Credential
	,
	# Specify this switch if you want to login with your Windows account credentials.
	[Parameter(Mandatory = $false, ParameterSetName = 'name-integrated')]
	[Parameter(Mandatory = $false, ParameterSetName = 'string-integrated')]
	[Alias('WindowsAuthentication')]
	[Switch] $IntegratedSecurity = $true
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
		$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder;
		$builder.psbase.DataSource = $ServerInstance;
		if($PSBoundParameters.ContainsKey('Database')) 
		{
			$builder.psbase.InitialCatalog = $Database;
		}
		$builder.psbase.IntegratedSecurity = $false;
		$builder.psbase.UserID = $Username;
		$builder.psbase.Password = $Password;
	} 
	else 
	{
		$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder($ConnectionString);
		$ServerInstance = $builder.psbase.DataSource;
		$Database = $builder.psbase.InitialCatalog;
	}
	
	if($PSCmdlet.ParameterSetName.EndsWith('-secure')) 
	{
		$Username = $Credential.Username;
		$Password = $Credential.GetNetworkCredential().Password;
	}
	
	if($PSCmdlet.ParameterSetName.EndsWith('-plain')) 
	{
		$builder.psbase.UserID = $Username;
		$builder.psbase.Password = $Password;
		$builder.psbase.IntegratedSecurity = $false
	} 
	else 
	{
		if($PSCmdlet.ParameterSetName -eq 'string-integrated' -And !$IntegratedSecurity)
		{
			# N/A
		}
		else
		{
			$builder.psbase.IntegratedSecurity = $true
			# Clear out sensitive information in case it was passed in from the caller
			if($builder.PSBase.ContainsKey('UserID')) { $null = $builder.PSBase.Remove('UserID'); }
			if($builder.PSBase.ContainsKey('User ID')) { $null = $builder.PSBase.Remove('User ID'); }
			if($builder.PSBase.ContainsKey('Password')) { $null = $builder.PSBase.Remove('Password'); }
		}
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
			$Result = Invoke-CmdText -ConnectionString $ConnectionString -Query $Query -As $As;
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

if($MyInvocation.ScriptName) { Export-ModuleMember -Function Invoke-SqlCmd; } 

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
