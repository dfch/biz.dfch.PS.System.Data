
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

Describe -Tags "Test-Invoke-SqlCmd" "Test-Invoke-SqlCmd" {

	Mock Export-ModuleMember { return $null; }
	
	. "$here\$sut"

	Context "Invoke-SqlCmd-PositiveTests" {
		It "SelectVersionAsDefault-ShouldReturnCorrectContent" -Test {

			# Arrange
			$Query = 'SELECT @@VERSION As [Version]';

				$ResultVersion = @"
Microsoft SQL Server 2008 R2 (SP2) - 10.50.4033.0 (X64)
        Jul  9 2014 16:04:25
        Copyright (c) Microsoft Corporation
        Express Edition (64-bit) on Windows NT 6.1 <X64> (Build 7601: Service Pack 1) (Hypervisor)
"@
			Mock Invoke-SqlCmdText -Verifiable -MockWith { 
				$OutputParameter = @{};
				$OutputParameter.Version = @"
Microsoft SQL Server 2008 R2 (SP2) - 10.50.4033.0 (X64)
        Jul  9 2014 16:04:25
        Copyright (c) Microsoft Corporation
        Express Edition (64-bit) on Windows NT 6.1 <X64> (Build 7601: Service Pack 1) (Hypervisor)
"@
				return $OutputParameter;
				}

			# Act
			$result = Invoke-SqlCmd -ServerInstance ".\SQLEXPRESS" $Query -As Default;

			# Assert
			Assert-VerifiableMocks;
			# Assert-MockCalled Invoke-SqlCmdText -Exactly 1;

			# Assert result
			[String]::IsNullOrWhiteSpace($result) | Should Be $false;
			$result -is [Hashtable] | Should Be $true;
			$result.ContainsKey('Version') | Should Be $true;
			$result.Version | Should Be $ResultVersion;
		}
	}

	Context "Invoke-SqlCmd-FormatTests" {
		It "SelectVersionAsXmlPretty-ShouldReturnCorrectFormat" -Test {

			# Arrange
			$Query = 'SELECT @@VERSION As [Version]';

			Mock Invoke-SqlCmdText -Verifiable -MockWith { 
				$OutputParameter = @"
<?xml version="1.0"?>
<Objects>
  <Object Type="System.Collections.ArrayList">
    <Property Type="System.Collections.Hashtable">
      <Property Name="Key" Type="System.String">Version</Property>
      <Property Name="Value" Type="System.String">Microsoft SQL Server 2008 R2 (SP2) - 10.50.4033.0 (X64)
        Jul  9 2014 16:04:25
        Copyright (c) Microsoft Corporation
        Express Edition (64-bit) on Windows NT 6.1 &lt;X64&gt; (Build 7601: Service Pack 1) (Hypervisor)
</Property>
    </Property>
  </Object>
</Objects>
"@
				return $OutputParameter;
				}

			# Act
			$result = Invoke-SqlCmd -ServerInstance ".\SQLEXPRESS" $Query -As Xml-Pretty;

			# Assert
			Assert-VerifiableMocks;
			# Assert-MockCalled Invoke-SqlCmdText -Exactly 1;

			# Assert result
			[String]::IsNullOrWhiteSpace($result) | Should Be $false;
			$result -is [String] | Should Be $true;
			[xml] $ConvertedFormat = $result;
			$ConvertedFormat -is [System.Xml.XmlDocument] | Should Be $true;
		}
		It "SelectVersionAsXml-ShouldReturnCorrectFormat" -Test {

			# Arrange
			$Query = 'SELECT @@VERSION As [Version]';

			Mock Invoke-SqlCmdText -Verifiable -MockWith { 
				$OutputParameter = @"
<?xml version="1.0"?><Objects><Object Type="System.Collections.ArrayList"><Property Type="System.Collections.Hashtable"><Property Name="Key" Type="System.String">Version</Property><Property Name="Value" Type="System.String">Microsoft SQL Server 2008 R2 (SP2) - 10.50.4033.0 (X64)
        Jul  9 2014 16:04:25
        Copyright (c) Microsoft Corporation
        Express Edition (64-bit) on Windows NT 6.1 &lt;X64&gt; (Build 7601: Service Pack 1) (Hypervisor)
</Property></Property></Object></Objects>
"@
				return $OutputParameter;
				}

			# Act
			$result = Invoke-SqlCmd -ServerInstance ".\SQLEXPRESS" $Query -As Xml;

			# Assert
			Assert-VerifiableMocks;
			# Assert-MockCalled Invoke-SqlCmdText -Exactly 1;

			# Assert result
			[String]::IsNullOrWhiteSpace($result) | Should Be $false;
			$result -is [String] | Should Be $true;
			[xml] $ConvertedFormat = $result;
			$ConvertedFormat -is [System.Xml.XmlDocument] | Should Be $true;
		}
		It "SelectVersionAsJsonPretty-ShouldReturnCorrectFormat" -Test {

			# Arrange
			$Query = 'SELECT @@VERSION As [Version]';

			Mock Invoke-SqlCmdText -Verifiable -MockWith { 
				$OutputParameter = @"
[
    {
        "Version":  "Microsoft SQL Server 2008 R2 (SP2) - 10.50.4033.0 (X64) \n\tJul  9 2014 16:04:25 \n\tCopyright (c) Microsoft Corporation\n\tExpress Edition (64-bit) on Windows NT 6.1 \u003cX64\u003e (Build 7601: Service Pack 1) (Hypervisor)\n"
    }
]
"@
				return $OutputParameter;
				}

			# Act
			$result = Invoke-SqlCmd -ServerInstance ".\SQLEXPRESS" $Query -As Json-Pretty;

			# Assert
			Assert-VerifiableMocks;
			# Assert-MockCalled Invoke-SqlCmdText -Exactly 1;

			# Assert result
			[String]::IsNullOrWhiteSpace($result) | Should Be $false;
			$result -is [String] | Should Be $true;
			$ConvertedFormat = $result | ConvertFrom-Json;
			$ConvertedFormat -is [PSCustomObject] | Should Be $true;
		}
		It "SelectVersionAsJson-ShouldReturnCorrectFormat" -Test {

			# Arrange
			$Query = 'SELECT @@VERSION As [Version]';

			Mock Invoke-SqlCmdText -Verifiable -MockWith { 
				$OutputParameter = @"
[{"Version":"Microsoft SQL Server 2008 R2 (SP2) - 10.50.4033.0 (X64) \n\tJul  9 2014 16:04:25 \n\tCopyright (c) Microsoft Corporation\n\tExpress Edition (64-bit) on Windows NT 6.1 \u003cX64\u003e (Build 7601: Service Pack 1) (Hypervisor)\n"}]
"@
				return $OutputParameter;
				}

			# Act
			$result = Invoke-SqlCmd -ServerInstance ".\SQLEXPRESS" $Query -As Json;

			# Assert
			Assert-VerifiableMocks;
			# Assert-MockCalled Invoke-SqlCmdText -Exactly 1;

			# Assert result
			[String]::IsNullOrWhiteSpace($result) | Should Be $false;
			$result -is [String] | Should Be $true;
			$ConvertedFormat = $result | ConvertFrom-Json;
			$ConvertedFormat -is [PSCustomObject] | Should Be $true;
		}
		It "SelectVersionAsDefault-ShouldReturnCorrectFormat" -Test {

			# Arrange
			$Query = 'SELECT @@VERSION As [Version]';

			Mock Invoke-SqlCmdText -Verifiable -MockWith { 
				$OutputParameter = @{};
				$OutputParameter.Version = @"
Microsoft SQL Server 2008 R2 (SP2) - 10.50.4033.0 (X64)
        Jul  9 2014 16:04:25
        Copyright (c) Microsoft Corporation
        Express Edition (64-bit) on Windows NT 6.1 <X64> (Build 7601: Service Pack 1) (Hypervisor)
"@
				return $OutputParameter;
				}

			# Act
			$result = Invoke-SqlCmd -ServerInstance ".\SQLEXPRESS" $Query -As Default;

			# Assert
			Assert-VerifiableMocks;
			# Assert-MockCalled Invoke-SqlCmdText -Exactly 1;

			# Assert result
			[String]::IsNullOrWhiteSpace($result) | Should Be $false;
			$result -is [Hashtable] | Should Be $true;
		}
		It "SelectVersion-ShouldReturnCorrectFormat" -Test {

			# Arrange
			$Query = 'SELECT @@VERSION As [Version]';

			Mock Invoke-SqlCmdText -Verifiable -MockWith { 
				$OutputParameter = @{};
				$OutputParameter.Version = @"
Microsoft SQL Server 2008 R2 (SP2) - 10.50.4033.0 (X64)
        Jul  9 2014 16:04:25
        Copyright (c) Microsoft Corporation
        Express Edition (64-bit) on Windows NT 6.1 <X64> (Build 7601: Service Pack 1) (Hypervisor)
"@
				return $OutputParameter;
				}

			# Act
			$result = Invoke-SqlCmd -ServerInstance ".\SQLEXPRESS" $Query;

			# Assert
			Assert-VerifiableMocks;
			# Assert-MockCalled Invoke-SqlCmdText -Exactly 1;

			# Assert result
			[String]::IsNullOrWhiteSpace($result) | Should Be $false;
			$result -is [Hashtable] | Should Be $true;
		}
	}
}

##
 #
 #
 # Copyright 2015 Ronald Rink, d-fens GmbH
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUeAGWz4KfrllAQstReVPmHF79
# jECgggkHMIIEKTCCAxGgAwIBAgILBAAAAAABMYnGN+gwDQYJKoZIhvcNAQELBQAw
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
# SIb3DQEJBDEWBBRrvhWeYCmZu2ivYsEX5ikP80BsGDANBgkqhkiG9w0BAQEFAASC
# AQAgU2I3L/MvwA/sqEg0tJLzEYY5N9s8Qgp1vEMBfXII4OCte4NlEKzrre5Gmh8G
# hb0POGh4xzSmZCte1LLZlah6OdhNWUnSlFHoQ9bRMB06MeVQxga8YDvyGwZum520
# iSjov4LYt1oIweBggUxkDyk2Rbq0HFTwXNVUtqSlQ2ix+tjkNZdV+W7qD45OqkEs
# Sq7a0UpHSN/DHJCZGTaaIU74S5MEtFHF056gt0X9Y8zR5JNOoN53JOY/A1VuQFPg
# sORu788qf9WchrHtQZ64NrKaywGurbN+b0W2kZeYmwmbzcOGs9lgjEMl65RuRgLN
# /ZCfGrjvymrbUoF1x8kBa8iX
# SIG # End signature block
