function Invoke-SqlCmdText {
[CmdletBinding(
	SupportsShouldProcess = $false
)]
Param
(
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

try 
{
	$fReturn = $false;
	$OutputParameter = $null

	$Connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString);
	$Command = New-Object System.Data.SqlClient.Sqlcommand($Query, $Connection);
	$Command.CommandTimeout = $ConnectionTimeout;
	$Connection.Open();

	$DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter($Command);
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
		$builder.psbase.IntegratedSecurity = $true
		# Clear out sensitive information in case it was passed in from the caller
		if($builder.PSBase.ContainsKey('UserID')) { $null = $builder.PSBase.Remove('UserID'); }
		if($builder.PSBase.ContainsKey('User ID')) { $null = $builder.PSBase.Remove('User ID'); }
		if($builder.PSBase.ContainsKey('Password')) { $null = $builder.PSBase.Remove('Password'); }
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
			$Result = Invoke-SqlCmdText -ConnectionString $ConnectionString -Query $Query -As $As;
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
			Log-Critical $fn ("[WebException] Request FAILED with Status '{0}'. [{1}]." -f $_.Status, $_);
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

##
 #
 #
 # Copyright 2014-2015 Ronald Rink, d-fens GmbH
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
 #


# SIG # Begin signature block
# MIILrgYJKoZIhvcNAQcCoIILnzCCC5sCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQULVsp8yy+Yk3u+MpSK1t3Mn8z
# 4d+gggkHMIIEKTCCAxGgAwIBAgILBAAAAAABMYnGN+gwDQYJKoZIhvcNAQELBQAw
# TDEgMB4GA1UECxMXR2xvYmFsU2lnbiBSb290IENBIC0gUjMxEzARBgNVBAoTCkds
# b2JhbFNpZ24xEzARBgNVBAMTCkdsb2JhbFNpZ24wHhcNMTEwODAyMTAwMDAwWhcN
# MTkwODAyMTAwMDAwWjBaMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2ln
# biBudi1zYTEwMC4GA1UEAxMnR2xvYmFsU2lnbiBDb2RlU2lnbmluZyBDQSAtIFNI
# QTI1NiAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAo+/Rnynp
# 2NOCdjxioNJJ1hYe8c/w0LpIQwMtpx3yATRJpBDpYhP0E/QWg7XVV0JIhiuVWIfq
# KAR0y3IRD2Em4focYRXHKJtNC4IPJiuQOpbtpNBrKZz1YYjmpFdv7vRw0I0X3uZm
# dl90Hl4MUzhdkPTfMC0bE9F5mFQaSzgE9AfEIwPTksv3gF2qnFYGRC1BTEi0Lew1
# kprGldf1zpAx4nazYbjxdVdCrDvOK8iQSei3Js+7DInL0MOjaqHJ1eOcUytXJv5W
# mnb9YUaiYOwpRkfyzeCCYsYEWuftTkBcSAZ9nV/ndMmehGUNW97c0yQctBQR66u/
# xB+kupnQF1g1zQIDAQABo4H9MIH6MA4GA1UdDwEB/wQEAwIBBjASBgNVHRMBAf8E
# CDAGAQH/AgEAMB0GA1UdDgQWBBQZSrha5E0xpRTlXuwvoxz6gIwyazBHBgNVHSAE
# QDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2ln
# bi5jb20vcmVwb3NpdG9yeS8wNgYDVR0fBC8wLTAroCmgJ4YlaHR0cDovL2NybC5n
# bG9iYWxzaWduLm5ldC9yb290LXIzLmNybDATBgNVHSUEDDAKBggrBgEFBQcDAzAf
# BgNVHSMEGDAWgBSP8Et/qC5FJK5NUPpjmove4t0bvDANBgkqhkiG9w0BAQsFAAOC
# AQEAebBpNOIFh/b+1GAsL4Z5NAPgsQeTDIRc+eTcbM9utewKXLoL0GgxLj9kvQ+C
# a2Z3gX/GKaUX2PCJTYMkEfZu/p3hSAoooOJ7JICk7MKaANewbWzNiNUVeM8T+Yil
# c03BNivcy87bfnzSi+8vvbNPTTqtu2JuKJPEDMvZ5srgEQKUA7C9P5QoVpAeU8In
# 1ck8zRpjHoJZFbZAyqeBqsNVrzPRtXXoCepHCEgi+10b8yx6aX7F11peVjM8rVfo
# kyVCw9JecTtKHFTtqVWsKAXHxGxd3DyT9mk8glHOGhU9XgFz/0Ci6rSu04767l1s
# R8dB9dRWV/IYNzLW1MxL9nHgdjCCBNYwggO+oAMCAQICEhEhDRayW4wRltP+V8mG
# Eea62TANBgkqhkiG9w0BAQsFADBaMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xv
# YmFsU2lnbiBudi1zYTEwMC4GA1UEAxMnR2xvYmFsU2lnbiBDb2RlU2lnbmluZyBD
# QSAtIFNIQTI1NiAtIEcyMB4XDTE1MDUwNDE2NDMyMVoXDTE4MDUwNDE2NDMyMVow
# VTELMAkGA1UEBhMCQ0gxDDAKBgNVBAgTA1p1ZzEMMAoGA1UEBxMDWnVnMRQwEgYD
# VQQKEwtkLWZlbnMgR21iSDEUMBIGA1UEAxMLZC1mZW5zIEdtYkgwggEiMA0GCSqG
# SIb3DQEBAQUAA4IBDwAwggEKAoIBAQDNPSzSNPylU9jFM78Q/GjzB7N+VNqikf/u
# se7p8mpnBZ4cf5b4qV3rqQd62rJHRlAsxgouCSNQrl8xxfg6/t/I02kPvrzsR4xn
# DgMiVCqVRAeQsWebafWdTvWmONBSlxJejPP8TSgXMKFaDa+2HleTycTBYSoErAZS
# WpQ0NqF9zBadjsJRVatQuPkTDrwLeWibiyOipK9fcNoQpl5ll5H9EG668YJR3fqX
# 9o0TQTkOmxXIL3IJ0UxdpyDpLEkttBG6Y5wAdpF2dQX2phrfFNVY54JOGtuBkNGM
# SiLFzTkBA1fOlA6ICMYjB8xIFxVvrN1tYojCrqYkKMOjwWQz5X8zAgMBAAGjggGZ
# MIIBlTAOBgNVHQ8BAf8EBAMCB4AwTAYDVR0gBEUwQzBBBgkrBgEEAaAyATIwNDAy
# BggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9y
# eS8wCQYDVR0TBAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzBCBgNVHR8EOzA5MDeg
# NaAzhjFodHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL2dzL2dzY29kZXNpZ25zaGEy
# ZzIuY3JsMIGQBggrBgEFBQcBAQSBgzCBgDBEBggrBgEFBQcwAoY4aHR0cDovL3Nl
# Y3VyZS5nbG9iYWxzaWduLmNvbS9jYWNlcnQvZ3Njb2Rlc2lnbnNoYTJnMi5jcnQw
# OAYIKwYBBQUHMAGGLGh0dHA6Ly9vY3NwMi5nbG9iYWxzaWduLmNvbS9nc2NvZGVz
# aWduc2hhMmcyMB0GA1UdDgQWBBTNGDddiIYZy9p3Z84iSIMd27rtUDAfBgNVHSME
# GDAWgBQZSrha5E0xpRTlXuwvoxz6gIwyazANBgkqhkiG9w0BAQsFAAOCAQEAAAps
# OzSX1alF00fTeijB/aIthO3UB0ks1Gg3xoKQC1iEQmFG/qlFLiufs52kRPN7L0a7
# ClNH3iQpaH5IEaUENT9cNEXdKTBG8OrJS8lrDJXImgNEgtSwz0B40h7bM2Z+0DvX
# DvpmfyM2NwHF/nNVj7NzmczrLRqN9de3tV0pgRqnIYordVcmb24CZl3bzpwzbQQy
# 14Iz+P5Z2cnw+QaYzAuweTZxEUcJbFwpM49c1LMPFJTuOKkUgY90JJ3gVTpyQxfk
# c7DNBnx74PlRzjFmeGC/hxQt0hvoeaAiBdjo/1uuCTToigVnyRH+c0T2AezTeoFb
# 7ne3I538hWeTdU5q9jGCAhEwggINAgEBMHAwWjELMAkGA1UEBhMCQkUxGTAXBgNV
# BAoTEEdsb2JhbFNpZ24gbnYtc2ExMDAuBgNVBAMTJ0dsb2JhbFNpZ24gQ29kZVNp
# Z25pbmcgQ0EgLSBTSEEyNTYgLSBHMgISESENFrJbjBGW0/5XyYYR5rrZMAkGBSsO
# AwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqG
# SIb3DQEJBDEWBBTwtCcV2EL3hNTLj+E8k9K1QcxcbDANBgkqhkiG9w0BAQEFAASC
# AQAjzCZ1nGJF//8gDYP6yCafTrK/EN+0B6+mQ/aT3dGjKS0QBxd+cmxnMCMr4rqF
# hLpQYSEaVdrlWKEkThKSbCHFGdrb02D+WGBIEylVR82Yp51hEudx7PUOjzTkAuyq
# 7En4qHgz/TO+GTMUkMyeigIu2xqY6d2rJNvTV+tBiNrgoClKm5swVTBREd0jYy0j
# YEk6bkqkvKATM87X7eh7/+hC0T0na25WM+iCy3TVGyJAvT/3xtNZ/gH38FW9aVB6
# T9nbCwJGnh+ZzWfY6Z9MRS+60skwPibNSLeVf5rkFaxoxMDqF785I0IKQP3cG/jU
# RVmkV6mSVQtwc8rcQWQwezWq
# SIG # End signature block
