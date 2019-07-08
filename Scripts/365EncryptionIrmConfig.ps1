<#
  Office 365 Message Encryption doesn't "just work"
  I think the problem lies between 365 and Azure fighting for who gets to be the tenant's protection authority
  I'm not really sure
  It's all a bit confusing trying to read the docs and seeing 3 different things named as the same thing trying to do the same thing, except when they're not

  Below is a cleaned up version of a script passed along from an excellent Microsoft Support representative named "Jorge G.C."
  #thankyoubasedjorge :pray:

  Requires PowerShell version >= 5.1 ($PSVersionTable)
#>

# Download the Azure Rights Management module 
# NOTE: It looks like this is being replaced by the AIPService module...I'll have to update this...https://docs.microsoft.com/en-us/azure/information-protection/install-powershell
Install-Module -Name AADRM –AllowClobber

Import-Module -Name AADRM

Get-Command -Module AADRM # Verify the install

# Connect to the Azure Rights PowerShell service and enable AADRM
$cred = Get-Credential

Connect-AADRMService -Credential $cred

Enable-AADRM

# Grab the configuration information required for message encryption
$rmsConfig = Get-AADRMConfiguration

$licenseUri = $rmsConfig.LicensingIntranetDistributionPointUrl

Disconnect-AADRMService # Peace out

# Connect to Exchange Online
# NOTE: If you have MFA enabled, as you should, you'll have to follow this: https://docs.microsoft.com/en-us/powershell/exchange/exchange-online/connect-to-exchange-online-powershell/mfa-connect-to-exchange-online-powershell?view=exchange-ps
$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $cred -Authentication Basic -AllowRedirection

Import-PSSession $session

# Collect the IRM configuration for Office 365:
$irmConfig = Get-IRMConfiguration

$list = $irmConfig.LicensingLocation

if (!$list) { $list = @() }

if (!$list.Contains($licenseUri)) { $list += $licenseUri }

Set-IRMConfiguration -LicensingLocation $list

Set-IRMConfiguration -AzureRMSLicensingEnabled $true -InternalLicensingEnabled $true

# Enable the Protect button within OWA:
Set-IRMConfiguration -SimplifiedClientAccessEnabled $true

# Enable server decryption (only run this if you have an on-prem server)
Set-IRMConfiguration -ClientAccessServerEnabled $true

# Verify that everything was configured correctly:
Get-IRMConfiguration

Test-IRMConfiguration -Sender adams@contoso.com # More stuff here: https://docs.microsoft.com/en-us/powershell/module/exchange/encryption-and-certificates/test-irmconfiguration
