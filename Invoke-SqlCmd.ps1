function Invoke-SqlCmdText {
	[CmdletBinding(
    SupportsShouldProcess = $false
    )]
Param(
	[Parameter(Mandatory = $true)]
	[string] $ConnectionString
	,
	[Parameter(Mandatory = $true, Position = 0)]
	[string] $Query
	,
	[ValidateSet('default', 'json', 'json-pretty', 'xml', 'xml-pretty', 'DataSet', 'Table')]
	[alias("ReturnFormat")]
	[string] $As = 'default'
	)

try {

	$fReturn = $false;
	$OutputParameter = $null

	$Connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString);
	$Command = New-Object System.Data.SqlClient.Sqlcommand($Query, $Connection);
	$Command.CommandTimeout = $ConnectionTimeout;
	$Connection.Open();

	$DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter($Command);
	$DataSet = New-Object System.Data.DataSet;
	$DataSetRows = $DataAdapter.Fill($DataSet);

	if($DataSetRows -gt 0) {
		$Table = $DataSet.Tables[0];
		switch($As) {
		'DataSet' { $r = $DataSet; }
		'Table' { $r = $Table; $DataSet.Dispose(); }
		Default { 
			$r = New-Object System.Collections.ArrayList($DataSetRows);
			$Columns = $DataSet.Tables[0].Columns.ColumnName;
			foreach($TableRow in $Table) {
				$rRow = @{}
				foreach($Column in $Columns) {
					$rRow.Add($Column, $TableRow[$Column]);
				} # foreach
				$null = $r.Add($rRow);
			} # foreach
			$DataSet.Dispose();
		}
		} # switch
	} # if

	switch($As) {
	'xml' { $OutputParameter = (ConvertTo-Xml -InputObject $r).OuterXml; }
	'xml-pretty' { $OutputParameter = Format-Xml -String (ConvertTo-Xml -InputObject $r).OuterXml; }
	'json' { $OutputParameter = ConvertTo-Json -InputObject $r -Compress; }
	'json-pretty' { $OutputParameter = ConvertTo-Json -InputObject $r; }
	Default { $OutputParameter = $r; }
	} # switch
	$fReturn = $true;
	return $OutputParameter;
}
catch {
	throw($_);
}
finally {
	# Clean up
	if($Command) {
		$Command.Dispose();
		Remove-Variable Command;
	} # if
	if($Connection -And $Connection.State -eq 'Open') {
		$Connection.Close();
	} # if
	if($Connection) {
		$Connection.Dispose();
		Remove-Variable Connection;
	} # if
} # finally
	
} # Invoke-SqlCmdText

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



.PARAMETER ServerInstance

Specifies the SQL Server and optionally a named instance.



.PARAMETER Database

Specifies the SQL Server database to connect to.



.PARAMETER QueryType

Specifies the type of query to perform. Currently only 'Text' and 'default' are supported.



.PARAMETER Username

SQL username with which to perform login.



.PARAMETER Password

SQL plaintext password with which to perform login.



.PARAMETER Credentials

Encrypted SQL credentials as [System.Management.Automation.PSCredential] with which to perform login.



.PARAMETER IntegratedSecurity

Specify this switch if you want to login with your Windows account credentials.



.PARAMETER ConnectionTimeout

This parameter (in seconds) overrides the default SqlClient Command connection timeout.



.PARAMETER As

Lets you specify the return format of the SQL query. Default is an (array of) hashtable.



.EXAMPLE

Get all system table names from default database with Windows authentication. Result is an array of hashtables.

Invoke-SqlCmd -ServerInstance '.\SQLEXPRESS' 'SELECT name, type_desc FROM [sys].[tables]' -IntegratedSecurity;



.EXAMPLE

Get all system table names from default database with Windows authentication. Result is a SQL DataSet. 
Note: You have to manually Dispose() this data set after use.

Invoke-SqlCmd -ServerInstance '.\SQLEXPRESS' 'SELECT name, type_desc FROM [sys].[tables]' -IntegratedSecurity -As DataSet;



.EXAMPLE

Get all system table names from default database with Windows authentication. Result is a JSON string. 

Invoke-SqlCmd -ServerInstance '.\SQLEXPRESS' 'SELECT TOP 3 name, type_desc FROM [sys].[tables]' -IntegratedSecurity -As json-pretty;
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

Login with SQL Credentials and get version information from named SQL instance.

Invoke-SqlCmd -ServerInstance '.\SQLEXPRESS' 'SELECT name FROM [sys].[tables]' -IntegratedSecurity;



.EXAMPLE

Login with SQL Credentials and get version information from named SQL instance.

Invoke-SqlCmd -ServerInstance '.\SQLEXPRESS' -Username 'Edgar.Schnittenfittich' -Password 'P@ssL0rd' 'SELECT @@VERSION'



.EXAMPLE

Login with integrated security to named SQL instance 'SERVER1\SQLEXPRESS' by using a connection string but override specified credentials.

Invoke-SqlCmd -ConnectionString 'Data Source=SERVER1\SQLEXPRESS;Initial Catalog=CumulusCfg;Integrated Security=False;User ID=sa;Password=P@ssw0rd' 'SELECT @@VERSION' -IntegratedSecurity



.EXAMPLE

Login with integrated security to a (LocalDB) file database via a ConnectionString.

Invoke-SqlCmd -ConnectionString 'Data Source=(LocalDB)\v11.0;AttachDbFilename="C:\VS\prj1\bin\Data\ApplicationDatabase.mdf";Integrated Security=True;Connect Timeout=30' 'SELECT @@VERSION AS [Version]' -IntegratedSecurity
Name    Value
----    -----
Version Microsoft SQL Server 2012 (SP1) - 11.0.3000.0 (X64) ...


.LINK

Online Version: http://dfch.biz/biz/dfch/PS/System/Data/Invoke-SqlCmd/


.NOTES

When returning a DataSet you have to manually dispose it after use (see QueryType option).

Requires Powershell v3.
Requires .NET Framework v4.5.

Requires module 'biz.dfch.PS.System.Logging'.
Requires module 'biz.dfch.PS.System.Utilities'.

#>
	[CmdletBinding(
    SupportsShouldProcess = $true
	,
    ConfirmImpact = "Low"
	,
	DefaultParameterSetName = "name-integrated"
	,
	HelpURI = 'http://dfch.biz/biz/dfch/PS/System/Data/Invoke-SqlCmd/'
    )]
Param(
	[Parameter(Mandatory = $true, ParameterSetName = 'name-plain')]
	[Parameter(Mandatory = $true, ParameterSetName = 'name-secure')]
	[Parameter(Mandatory = $true, ParameterSetName = 'name-integrated')]
	[string] $ServerInstance
	,
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
	[Parameter(Mandatory = $false)]
	[int] $ConnectionTimeout = 45
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'name-plain')]
	[Parameter(Mandatory = $false, ParameterSetName = 'string-plain')]
	[string] $Username
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'name-plain')]
	[Parameter(Mandatory = $false, ParameterSetName = 'string-plain')]
	[string] $Password
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'name-secure')]
	[Parameter(Mandatory = $false, ParameterSetName = 'string-secure')]
	[PSCredential] $Credential
	,
	[Parameter(Mandatory = $false, ParameterSetName = 'name-integrated')]
	[Parameter(Mandatory = $false, ParameterSetName = 'string-integrated')]
	[Alias('WindowsAuthentication')]
	[Switch] $IntegratedSecurity = $true
	,
	[ValidateSet('default', 'Text', 'TableDirect', 'StoredProcedure')]
	[Parameter(Mandatory = $false)]
	[string] $QueryType = 'default'
	,
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
try {
	# Parameter validation

	# Build connection string depending on input parameters
	if($PSCmdlet.ParameterSetName.StartsWith('name-')) {
		$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder;
		$builder.psbase.DataSource = $ServerInstance;
		if($PSBoundParameters.ContainsKey('Database')) {
			$builder.psbase.InitialCatalog = $Database;
		} # if
		$builder.psbase.IntegratedSecurity = $false;
		$builder.psbase.UserID = $Username;
		$builder.psbase.Password = $Password;
	} else {
		$builder = New-Object System.Data.SqlClient.SqlConnectionStringBuilder($ConnectionString);
		$ServerInstance = $builder.psbase.DataSource;
		$Database = $builder.psbase.InitialCatalog;
	} # if
	if($PSCmdlet.ParameterSetName.EndsWith('-secure')) {
		$Username = $Credential.Username;
		$Password = $Credential.GetNetworkCredential().Password;
	} # if
	if($PSCmdlet.ParameterSetName.EndsWith('-plain')) {
		$builder.psbase.UserID = $Username;
		$builder.psbase.Password = $Password;
		$builder.psbase.IntegratedSecurity = $false
	} else {
		$builder.psbase.IntegratedSecurity = $true
		# Clear out sensitive information in case it was passed in from the caller
		if($builder.PSBase.ContainsKey('UserID')) { $null = $builder.PSBase.Remove('UserID'); }
		if($builder.PSBase.ContainsKey('User ID')) { $null = $builder.PSBase.Remove('User ID'); }
		if($builder.PSBase.ContainsKey('Password')) { $null = $builder.PSBase.Remove('Password'); }
	} # if
	$ConnectionString = $builder.ToString();

	if(!$PSCmdlet.ShouldProcess($Query)) {
		$fReturn = $false;
		$OutputParameter = $null;
		throw($gotoSuccess);
	} # if

	$Result = $null;
	if($QueryType -eq 'Default') { $QueryType = 'Text'; }
	switch($QueryType) {
	'Text' {
		$Result = Invoke-SqlCmdText -ConnectionString $ConnectionString -Query $Query -As $As;
	}
	default {
		$msg = "This QueryType has not been implemented: '{0}'" -f $QueryType;
		Log-Error $fn $msg;
		$e = New-CustomErrorRecord -m $msg -cat NotImplemented -o $QueryType; 
		throw($gotoError);
	}
	} # switch
	$fReturn = $true;
	$OutputParameter = $Result;
	# $PSCmdlet.ThrowTerminatingError('no error - just kidding');

} # try
catch {
	if($gotoSuccess -eq $_.Exception.Message) {
		$fReturn = $true;
	} else {
		[string] $ErrorText = "catch [$($_.FullyQualifiedErrorId)]";
		$ErrorText += (($_ | fl * -Force) | Out-String);
		$ErrorText += (($_.Exception | fl * -Force) | Out-String);
		$ErrorText += (Get-PSCallStack | Out-String);
		
		if($_.Exception -is [System.Net.WebException]) {
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Status, $_);
			Log-Debug $fn $ErrorText -fac 3;
		} # [System.Net.WebException]
		else {
			Log-Error $fn $ErrorText -fac 3;
			if($gotoError -eq $_.Exception.Message) {
				Log-Error $fn $e.Exception.Message;
				$PSCmdlet.ThrowTerminatingError($e);
			} elseif($gotoFailure -eq $_.Exception.Message) { 
				Write-Verbose ("$fn`n$ErrorText"); 
			} else {
				throw($_);
			} # if
		} # other exceptions
		$fReturn = $false;
		$OutputParameter = $null;
	} # !$gotoSuccess
} # catch
finally {
	# Clean up
	# N/A

	$datEnd = [datetime]::Now;
	Log-Debug -fn $fn -msg ("RET. fReturn: [{0}]. Execution time: [{1}]ms. Started: [{2}]." -f $fReturn, ($datEnd - $datBegin).TotalMilliseconds, $datBegin.ToString('yyyy-MM-dd HH:mm:ss.fffzzz')) -fac 2;
} # finally
return $OutputParameter;

} # Invoke-SqlCmd
Export-ModuleMember -Function Invoke-SqlCmd;

