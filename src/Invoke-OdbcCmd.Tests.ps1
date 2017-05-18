
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")

Describe -Tags "Test-Invoke-OdbcCmd" "Test-Invoke-OdbcCmd" {

	Mock Export-ModuleMember { return $null; }
	
	. "$here\$sut"
	. "$here\Invoke-CmdText"

	Context "Invoke-OdbcCmd-PositiveTests" {
		It "SelectIdentityAsDefault-ShouldReturnCorrectContent" -Test {

			# Arrange
			$Query = 'SELECT @@Identity';
			$Driver = '{SQL Server}';
			$Dbq = 'C:\arbitrary-database.mdb';

			$ResultIdentity = "0";
			
			Mock Invoke-CmdText -Verifiable -MockWith { 
				$OutputParameter = @{};
				$OutputParameter.Expr1000 = "0";
				return $OutputParameter;
			}

			# Act
			$result = Invoke-OdbcCmd $Query -Dbq $Dbq -Driver $Driver -As default;

			# Assert
			Assert-VerifiableMocks;
			# Assert-MockCalled Invoke-CmdText -Exactly 1;

			# Assert result
			[String]::IsNullOrWhiteSpace($result) | Should Be $false;
			$result -is [Hashtable] | Should Be $true;
			$result.ContainsKey('Expr1000') | Should Be $true;
			$result.Expr1000 | Should Be $ResultIdentity;
		}
	}

	Context "Invoke-OdbcCmd-FormatTests" {
		It "SelectIdentityAsXmlPretty-ShouldReturnCorrectFormat" -Test {

			# Arrange
			$Query = 'SELECT @@Identity';
			$Driver = '{SQL Server}';
			$Dbq = 'C:\arbitrary-database.mdb';

			Mock Invoke-CmdText -Verifiable -MockWith { 
				$OutputParameter = @"
<?xml version="1.0" encoding="utf-8"?>
<Objects>
  <Object Type="System.Collections.ArrayList">
    <Property Type="System.Collections.Hashtable">
      <Property Name="Key" Type="System.String">Expr1000</Property>
      <Property Name="Value" Type="System.Int32">0</Property>
    </Property>
  </Object>
</Objects>
"@
				return $OutputParameter;
			}

			# Act
			$result = Invoke-OdbcCmd $Query -Dbq $Dbq -Driver $Driver -As xml-pretty;

			# Assert
			Assert-VerifiableMocks;
			# Assert-MockCalled Invoke-CmdText -Exactly 1;

			# Assert result
			[String]::IsNullOrWhiteSpace($result) | Should Be $false;
			$result -is [String] | Should Be $true;
			[xml] $ConvertedFormat = $result;
			$ConvertedFormat -is [System.Xml.XmlDocument] | Should Be $true;
		}
		
		It "SelectIdentityAsXml-ShouldReturnCorrectFormat" -Test {

			# Arrange
			$Query = 'SELECT @@Identity';
			$Driver = '{SQL Server}';
			$Dbq = 'C:\arbitrary-database.mdb';

			Mock Invoke-CmdText -Verifiable -MockWith { 
				$OutputParameter = @"
<?xml version="1.0" encoding="utf-8"?><Objects><Object Type="System.Collections.ArrayList"><Property Type="System.Collections.Hashtable"><Property Name="Key" Type="System.String">Expr1000</Property><Property Name="Value" Type="System.Int32">0</Property></Property></Object></Objects>
"@
				return $OutputParameter;
			}

			# Act
			$result = Invoke-OdbcCmd $Query -Dbq $Dbq -Driver $Driver -As xml;

			# Assert
			Assert-VerifiableMocks;
			# Assert-MockCalled Invoke-CmdText -Exactly 1;

			# Assert result
			[String]::IsNullOrWhiteSpace($result) | Should Be $false;
			$result -is [String] | Should Be $true;
			[xml] $ConvertedFormat = $result;
			$ConvertedFormat -is [System.Xml.XmlDocument] | Should Be $true;
		}
		
		It "SelectIdentityAsJsonPretty-ShouldReturnCorrectFormat" -Test {

			# Arrange
			$Query = 'SELECT @@Identity';
			$Driver = '{SQL Server}';
			$Dbq = 'C:\arbitrary-database.mdb';

			Mock Invoke-CmdText -Verifiable -MockWith { 
				$OutputParameter = @"
[
    {
        "Expr1000":  0
    }
]
"@
				return $OutputParameter;
			}

			# Act
			$result = Invoke-OdbcCmd $Query -Dbq $Dbq -Driver $Driver -As json-pretty;

			# Assert
			Assert-VerifiableMocks;
			# Assert-MockCalled Invoke-CmdText -Exactly 1;

			# Assert result
			[String]::IsNullOrWhiteSpace($result) | Should Be $false;
			$result -is [String] | Should Be $true;
			$ConvertedFormat = $result | ConvertFrom-Json;
			$ConvertedFormat -is [PSCustomObject] | Should Be $true;
		}
		
		It "SelectIdentityAsJson-ShouldReturnCorrectFormat" -Test {

			# Arrange
			$Query = 'SELECT @@Identity';
			$Driver = '{SQL Server}';
			$Dbq = 'C:\arbitrary-database.mdb';

			Mock Invoke-CmdText -Verifiable -MockWith { 
				$OutputParameter = @"
[{"Expr1000":0}]
"@
				return $OutputParameter;
			}

			# Act
			$result = Invoke-OdbcCmd $Query -Dbq $Dbq -Driver $Driver -As json;

			# Assert
			Assert-VerifiableMocks;
			# Assert-MockCalled Invoke-CmdText -Exactly 1;

			# Assert result
			[String]::IsNullOrWhiteSpace($result) | Should Be $false;
			$result -is [String] | Should Be $true;
			$ConvertedFormat = $result | ConvertFrom-Json;
			$ConvertedFormat -is [PSCustomObject] | Should Be $true;
		}
		
		It "SelectIdentityAsDefault-ShouldReturnCorrectFormat" -Test {

			# Arrange
			$Query = 'SELECT @@Identity';
			$Driver = '{SQL Server}';
			$Dbq = 'C:\arbitrary-database.mdb';

			Mock Invoke-CmdText -Verifiable -MockWith { 
				$OutputParameter = @{};
				$OutputParameter.Expr1000 = "0";
				return $OutputParameter;
			}

			# Act
			$result = Invoke-OdbcCmd $Query -Dbq $Dbq -Driver $Driver -As default;

			# Assert
			Assert-VerifiableMocks;
			# Assert-MockCalled Invoke-CmdText -Exactly 1;

			# Assert result
			[String]::IsNullOrWhiteSpace($result) | Should Be $false;
			$result -is [Hashtable] | Should Be $true;
		}
		
		It "SelectIdentity-ShouldReturnCorrectFormat" -Test {

			# Arrange
			$Query = 'SELECT @@Identity';
			$Driver = '{SQL Server}';
			$Dbq = 'C:\arbitrary-database.mdb';

			Mock Invoke-CmdText -Verifiable -MockWith { 
				$OutputParameter = @{};
				$OutputParameter.Expr1000 = "0";
				return $OutputParameter;
			}

			# Act
			$result = Invoke-OdbcCmd $Query -Dbq $Dbq -Driver $Driver;

			# Assert
			Assert-VerifiableMocks;
			# Assert-MockCalled Invoke-CmdText -Exactly 1;

			# Assert result
			[String]::IsNullOrWhiteSpace($result) | Should Be $false;
			$result -is [Hashtable] | Should Be $true;
		}
	}
}

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
