$fn = $MyInvocation.MyCommand.Name;

Set-Variable gotoSuccess -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoSuccess';
Set-Variable gotoError -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoError';
Set-Variable gotoFailure -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoFailure';
Set-Variable gotoNotFound -Option 'Constant' -Value 'biz.dfch.System.Exception.gotoNotFound';

[string] $ModuleConfigFile = '{0}.xml' -f (Get-Item $PSCommandPath).BaseName;
[string] $ModuleConfigurationPathAndFile = Join-Path -Path $PSScriptRoot -ChildPath $ModuleConfigFile;
$mvar = $ModuleConfigFile.Replace('.xml', '').Replace('.', '_');
if($true -eq (Test-Path -Path $ModuleConfigurationPathAndFile)) {
	if($true -ne (Test-Path variable:$($mvar))) {
		Log-Debug $fn ("Loading module configuration file from: '{0}' ..." -f $ModuleConfigurationPathAndFile);
		Set-Variable -Name $mvar -Value (Import-Clixml -Path $ModuleConfigurationPathAndFile);
	} # if()
} # if()
if($true -ne (Test-Path variable:$($mvar))) {
	Write-Error "Could not find module configuration file '$ModuleConfigFile' in 'ENV:PSModulePath'.`nAborting module import...";
	break; # Aborts loading module.
} # if()
Export-ModuleMember -Variable $mvar;

[string] $ManifestFile = '{0}.psd1' -f (Get-Item $PSCommandPath).BaseName;
$ManifestPathAndFile = Join-Path -Path $PSScriptRoot -ChildPath $ManifestFile;
if( Test-Path -Path $ManifestPathAndFile)
{
	$Manifest = (Get-Content -raw $ManifestPathAndFile) | iex;
	foreach( $ScriptToProcess in $Manifest.ScriptsToProcess) 
	{ 
		$ModuleToRemove = (Get-Item (Join-Path -Path $PSScriptRoot -ChildPath $ScriptToProcess)).BaseName;
		if(Get-Module $ModuleToRemove)
		{ 
			Remove-Module $ModuleToRemove -ErrorAction:SilentlyContinue;
		}
	}
}

<#
 # ########################################
 # Version history
 # ########################################
 #
 # 2014-10-19; rrink; ADD: initial release
 #
 # ########################################
 #>

# SIG # Begin signature block
# MIILrgYJKoZIhvcNAQcCoIILnzCCC5sCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAC+e69gd3nwLXpQOzy4W74UU
# xWygggkHMIIEKTCCAxGgAwIBAgILBAAAAAABMYnGN+gwDQYJKoZIhvcNAQELBQAw
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
# SIb3DQEJBDEWBBQT34RnAgl2g5QWCGQfvswc8knU9TANBgkqhkiG9w0BAQEFAASC
# AQCpBRXUBBDsH5pHq7je/rdHtpzF8XHHO4GWyGhuZQzaTQen8svIEzMcQqIb/3Y8
# aFI3ZJK0s6WTC/UUeQr/tg//pVDY5bpo3AwFRJaxNM4brJKrotE6x+7+Bb6NzaQd
# dgm+hljznZ3NTRYfTM/TVkjgY+tNHWRMkWzOsixCuGy6igPhQLcglY/p35L/El/b
# aR76wOBZnQlekCiud9qwFxi1Zg864y6kd64WFKR+0gispE4oMrhQx9OlzouT5KVJ
# Rww2UU0feC5cqrqAbyRQ0jV8xEc6ANSOwyKHkkgrULQFOpuz923AvnMmyOqlGwuF
# S4jur+pkSMS531O1CDXAJMKC
# SIG # End signature block
