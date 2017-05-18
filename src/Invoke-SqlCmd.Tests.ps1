
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
