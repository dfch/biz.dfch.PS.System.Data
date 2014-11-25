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


# SIG # Begin signature block
# MIIW3AYJKoZIhvcNAQcCoIIWzTCCFskCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUDBLTg9NwsiqnspooGMupWlh
# 3nOgghGYMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw0xMTA0
# MTMxMDAwMDBaFw0yODAxMjgxMjAwMDBaMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFt
# cGluZyBDQSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlO9l
# +LVXn6BTDTQG6wkft0cYasvwW+T/J6U00feJGr+esc0SQW5m1IGghYtkWkYvmaCN
# d7HivFzdItdqZ9C76Mp03otPDbBS5ZBb60cO8eefnAuQZT4XljBFcm05oRc2yrmg
# jBtPCBn2gTGtYRakYua0QJ7D/PuV9vu1LpWBmODvxevYAll4d/eq41JrUJEpxfz3
# zZNl0mBhIvIG+zLdFlH6Dv2KMPAXCae78wSuq5DnbN96qfTvxGInX2+ZbTh0qhGL
# 2t/HFEzphbLswn1KJo/nVrqm4M+SU4B09APsaLJgvIQgAIMboe60dAXBKY5i0Eex
# +vBTzBj5Ljv5cH60JQIDAQABo4HlMIHiMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBRG2D7/3OO+/4Pm9IWbsN1q1hSpwTBHBgNV
# HSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2Ny
# bC5nbG9iYWxzaWduLm5ldC9yb290LmNybDAfBgNVHSMEGDAWgBRge2YaRQ2XyolQ
# L30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEATl5WkB5GtNlJMfO7FzkoG8IW
# 3f1B3AkFBJtvsqKa1pkuQJkAVbXqP6UgdtOGNNQXzFU6x4Lu76i6vNgGnxVQ380W
# e1I6AtcZGv2v8Hhc4EvFGN86JB7arLipWAQCBzDbsBJe/jG+8ARI9PBw+DpeVoPP
# PfsNvPTF7ZedudTbpSeE4zibi6c1hkQgpDttpGoLoYP9KOva7yj2zIhd+wo7AKvg
# IeviLzVsD440RZfroveZMzV+y5qKu0VN5z+fwtmK+mWybsd+Zf/okuEsMaL3sCc2
# SI8mbzvuTXYfecPlf5Y1vC0OzAGwjn//UYCAp5LUs0RGZIyHTxZjBzFLY7Df8zCC
# BCgwggMQoAMCAQICCwQAAAAAAS9O4TVcMA0GCSqGSIb3DQEBBQUAMFcxCzAJBgNV
# BAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMRAwDgYDVQQLEwdSb290
# IENBMRswGQYDVQQDExJHbG9iYWxTaWduIFJvb3QgQ0EwHhcNMTEwNDEzMTAwMDAw
# WhcNMTkwNDEzMTAwMDAwWjBRMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFs
# U2lnbiBudi1zYTEnMCUGA1UEAxMeR2xvYmFsU2lnbiBDb2RlU2lnbmluZyBDQSAt
# IEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsk8U5xC+1yZyqzaX
# 71O/QoReWNGKKPxDRm9+KERQC3VdANc8CkSeIGqk90VKN2Cjbj8S+m36tkbDaqO4
# DCcoAlco0VD3YTlVuMPhJYZSPL8FHdezmviaJDFJ1aKp4tORqz48c+/2KfHINdAw
# e39OkqUGj4fizvXBY2asGGkqwV67Wuhulf87gGKdmcfHL2bV/WIaglVaxvpAd47J
# MDwb8PI1uGxZnP3p1sq0QB73BMrRZ6l046UIVNmDNTuOjCMMdbbehkqeGj4KUEk4
# nNKokL+Y+siMKycRfir7zt6prjiTIvqm7PtcYXbDRNbMDH4vbQaAonRAu7cf9DvX
# c1Qf8wIDAQABo4H6MIH3MA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8ECDAGAQH/
# AgEAMB0GA1UdDgQWBBQIbti2nIq/7T7Xw3RdzIAfqC9QejBHBgNVHSAEQDA+MDwG
# BFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20v
# cmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2NybC5nbG9iYWxz
# aWduLm5ldC9yb290LmNybDATBgNVHSUEDDAKBggrBgEFBQcDAzAfBgNVHSMEGDAW
# gBRge2YaRQ2XyolQL30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEAIlzF3T30
# C3DY4/XnxY4JAbuxljZcWgetx6hESVEleq4NpBk7kpzPuUImuztsl+fHzhFtaJHa
# jW3xU01UOIxh88iCdmm+gTILMcNsyZ4gClgv8Ej+fkgHqtdDWJRzVAQxqXgNO4yw
# cME9fte9LyrD4vWPDJDca6XIvmheXW34eNK+SZUeFXgIkfs0yL6Erbzgxt0Y2/PK
# 8HvCFDwYuAO6lT4hHj9gaXp/agOejUr58CgsMIRe7CZyQrFty2TDEozWhEtnQXyx
# Axd4CeOtqLaWLaR+gANPiPfBa1pGFc0sGYvYcJzlLUmIYHKopBlScENe2tZGA7Bo
# DiTvSvYLJSTvJDCCBJ8wggOHoAMCAQICEhEhQFwfDtJYiCvlTYaGuhHqRTANBgkq
# hkiG9w0BAQUFADBSMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBu
# di1zYTEoMCYGA1UEAxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMjAe
# Fw0xMzA4MjMwMDAwMDBaFw0yNDA5MjMwMDAwMDBaMGAxCzAJBgNVBAYTAlNHMR8w
# HQYDVQQKExZHTU8gR2xvYmFsU2lnbiBQdGUgTHRkMTAwLgYDVQQDEydHbG9iYWxT
# aWduIFRTQSBmb3IgTVMgQXV0aGVudGljb2RlIC0gRzEwggEiMA0GCSqGSIb3DQEB
# AQUAA4IBDwAwggEKAoIBAQCwF66i07YEMFYeWA+x7VWk1lTL2PZzOuxdXqsl/Tal
# +oTDYUDFRrVZUjtCoi5fE2IQqVvmc9aSJbF9I+MGs4c6DkPw1wCJU6IRMVIobl1A
# cjzyCXenSZKX1GyQoHan/bjcs53yB2AsT1iYAGvTFVTg+t3/gCxfGKaY/9Sr7KFF
# WbIub2Jd4NkZrItXnKgmK9kXpRDSRwgacCwzi39ogCq1oV1r3Y0CAikDqnw3u7sp
# Tj1Tk7Om+o/SWJMVTLktq4CjoyX7r/cIZLB6RA9cENdfYTeqTmvT0lMlnYJz+iz5
# crCpGTkqUPqp0Dw6yuhb7/VfUfT5CtmXNd5qheYjBEKvAgMBAAGjggFfMIIBWzAO
# BgNVHQ8BAf8EBAMCB4AwTAYDVR0gBEUwQzBBBgkrBgEEAaAyAR4wNDAyBggrBgEF
# BQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYD
# VR0TBAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDBCBgNVHR8EOzA5MDegNaAz
# hjFodHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL2dzL2dzdGltZXN0YW1waW5nZzIu
# Y3JsMFQGCCsGAQUFBwEBBEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3NlY3VyZS5n
# bG9iYWxzaWduLmNvbS9jYWNlcnQvZ3N0aW1lc3RhbXBpbmdnMi5jcnQwHQYDVR0O
# BBYEFNSihEo4Whh/uk8wUL2d1XqH1gn3MB8GA1UdIwQYMBaAFEbYPv/c477/g+b0
# hZuw3WrWFKnBMA0GCSqGSIb3DQEBBQUAA4IBAQACMRQuWFdkQYXorxJ1PIgcw17s
# LOmhPPW6qlMdudEpY9xDZ4bUOdrexsn/vkWF9KTXwVHqGO5AWF7me8yiQSkTOMjq
# IRaczpCmLvumytmU30Ad+QIYK772XU+f/5pI28UFCcqAzqD53EvDI+YDj7S0r1tx
# KWGRGBprevL9DdHNfV6Y67pwXuX06kPeNT3FFIGK2z4QXrty+qGgk6sDHMFlPJET
# iwRdK8S5FhvMVcUM6KvnQ8mygyilUxNHqzlkuRzqNDCxdgCVIfHUPaj9oAAy126Y
# PKacOwuDvsu4uyomjFm4ua6vJqziNKLcIQ2BCzgT90Wj49vErKFtG7flYVzXMIIE
# rTCCA5WgAwIBAgISESFgd9/aXcgt4FtCBtsrp6UyMA0GCSqGSIb3DQEBBQUAMFEx
# CzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMScwJQYDVQQD
# Ex5HbG9iYWxTaWduIENvZGVTaWduaW5nIENBIC0gRzIwHhcNMTIwNjA4MDcyNDEx
# WhcNMTUwNzEyMTAzNDA0WjB6MQswCQYDVQQGEwJERTEbMBkGA1UECBMSU2NobGVz
# d2lnLUhvbHN0ZWluMRAwDgYDVQQHEwdJdHplaG9lMR0wGwYDVQQKDBRkLWZlbnMg
# R21iSCAmIENvLiBLRzEdMBsGA1UEAwwUZC1mZW5zIEdtYkggJiBDby4gS0cwggEi
# MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDTG4okWyOURuYYwTbGGokj+lvB
# go0dwNYJe7HZ9wrDUUB+MsPTTZL82O2INMHpQ8/QEMs87aalzHz2wtYN1dUIBUae
# dV7TZVme4ycjCfi5rlL+p44/vhNVnd1IbF/pxu7yOwkAwn/iR+FWbfAyFoCThJYk
# 9agPV0CzzFFBLcEtErPJIvrHq94tbRJTqH9sypQfrEToe5kBWkDYfid7U0rUkH/m
# bff/Tv87fd0mJkCfOL6H7/qCiYF20R23Kyw7D2f2hy9zTcdgzKVSPw41WTsQtB3i
# 05qwEZ3QCgunKfDSCtldL7HTdW+cfXQ2IHItN6zHpUAYxWwoyWLOcWcS69InAgMB
# AAGjggFUMIIBUDAOBgNVHQ8BAf8EBAMCB4AwTAYDVR0gBEUwQzBBBgkrBgEEAaAy
# ATIwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVw
# b3NpdG9yeS8wCQYDVR0TBAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzA+BgNVHR8E
# NzA1MDOgMaAvhi1odHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL2dzL2dzY29kZXNp
# Z25nMi5jcmwwUAYIKwYBBQUHAQEERDBCMEAGCCsGAQUFBzAChjRodHRwOi8vc2Vj
# dXJlLmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc2NvZGVzaWduZzIuY3J0MB0GA1Ud
# DgQWBBTwJ4K6WNfB5ea1nIQDH5+tzfFAujAfBgNVHSMEGDAWgBQIbti2nIq/7T7X
# w3RdzIAfqC9QejANBgkqhkiG9w0BAQUFAAOCAQEAB3ZotjKh87o7xxzmXjgiYxHl
# +L9tmF9nuj/SSXfDEXmnhGzkl1fHREpyXSVgBHZAXqPKnlmAMAWj0+Tm5yATKvV6
# 82HlCQi+nZjG3tIhuTUbLdu35bss50U44zNDqr+4wEPwzuFMUnYF2hFbYzxZMEAX
# Vlnaj+CqtMF6P/SZNxFvaAgnEY1QvIXI2pYVz3RhD4VdDPmMFv0P9iQ+npC1pmNL
# mCaG7zpffUFvZDuX6xUlzvOi0nrTo9M5F2w7LbWSzZXedam6DMG0nR1Xcx0qy9wY
# nq4NsytwPbUy+apmZVSalSvldiNDAfmdKP0SCjyVwk92xgNxYFwITJuNQIto4zGC
# BK4wggSqAgEBMGcwUTELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24g
# bnYtc2ExJzAlBgNVBAMTHkdsb2JhbFNpZ24gQ29kZVNpZ25pbmcgQ0EgLSBHMgIS
# ESFgd9/aXcgt4FtCBtsrp6UyMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQow
# CKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcC
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRCxVb358preMzkl41z
# 7mA3aeh7pzANBgkqhkiG9w0BAQEFAASCAQAAB7WotSUbuyeJi2wOgbQh0lFTRRht
# x3M1RXro5Da9dgHU6itqkf4EewHVtuXlqC4ZC2FAJix7sQa60B6h2p041mlSYg+n
# n7wNjdqVUgmEidWpUscQSnezm+PSJYHAAkSj9LJzf3TyM5JD6Czz+OpXEgvxK6Mb
# NEZT7OIzwnkWUr+ZHgPhQeiKVpZW01hEZrRgEGt0+SjFoYiXIDiGEBUQwsnzjvtX
# j6fS4cXVfM5kUIEVHgffO3RJn2QhLWgzM10x53crI3ZbCt62+q/KI/VG+9r/5Ucx
# XMQIZFGjLFE61Rxod/Aqt5i4OIsJ8IR/JLAjzripxOhn0JAN5kXZcpsvoYICojCC
# Ap4GCSqGSIb3DQEJBjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNV
# BAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0
# YW1waW5nIENBIC0gRzICEhEhQFwfDtJYiCvlTYaGuhHqRTAJBgUrDgMCGgUAoIH9
# MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE0MTEy
# NTE2MjU0OVowIwYJKoZIhvcNAQkEMRYEFOLg6jjx5PmWxET0x3SXIOqhay55MIGd
# BgsqhkiG9w0BCRACDDGBjTCBijCBhzCBhAQUjOafUBLh0aj7OV4uMeK0K947NDsw
# bDBWpFQwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2Ex
# KDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEhQFwf
# DtJYiCvlTYaGuhHqRTANBgkqhkiG9w0BAQEFAASCAQAXcndQwwX3JD6AQy/HJBIF
# zT5Hz3Sy8Pq1lDqUCcNKhEn9h/RCFRUeL37vzkVLBTh+Inap0aoo7mgq5Xq3LMSs
# 6eNAUMA94uoBQUCJtPk23KtZ0AaONKJHXi3b6uD60Aj/Omle1tRiRvHkmNcL1Y38
# lG4UWYy2XJy4FlGAm8L938ixpVO63vW5Qf/8wNzfSwc8y4e6bRojSn2A8iH30gw3
# xmUagHbxD86HnkR9J4m2EvYocJuplDiuDn7/JJ9OixHJaU2X7f3xh3IhTVy2+Dxb
# 2iVWr3ZRGRNGwcMuAdyG7kJLyp/2VAgOwJJ7Z5Cqzx6tDpdA64LwFcm/csyZstZ9
# SIG # End signature block
