<#

Below is the general workflow I use to swap user seats in bulk between Office 365 Business and Enterprise SKUs. 
In its current state, this "script" is intended to be used as a granular template of individually executed commands,
not a ".\ + enter" solution. However, it could serve as the foundation of such a solution once you get into the flow of things.

In order to run through this, you will need to install the Microsoft Azure Active Directory Module for Windows PowerShell.
Instructions to do so are here:
https://docs.microsoft.com/en-us/office365/enterprise/powershell/connect-to-office-365-powershell#connect-with-the-microsoft-azure-active-directory-module-for-windows-powershell

Shoutout to Jakob Østergaard Nielsen's blog article--It served as a succinct reference when building this out. 
(http://www.mistercloudtech.com/2017/03/28/how-to-switch-office-365-licenses-using-powershell/)
Refer to it if you run into any issues with my instructions or contact me at nathan@trustedtechteam.com

#>

# Hash table used to setup SKU target values. You'll need to update this with your target values received in #L29.
$targetSkus = @{
  AddLicenses = "domain:ENTERPRISEPACK"
  RemoveLicenses = "domain:O365_BUSINESS_ESSENTIALS"
}

# Login as your Global Admin user for the tenant
Connect-MsolService

# Grab list of SKUs associated with the tenant
# Make sure to use the output to update the hash table Values above!
Get-MsolAccountSku

# Get a list of accounts that have O365_BUSINESS_ESSENTIALS, or whatever you're trying to remove, assigned:
# This is not required, but I like to have it as an original source list and typically  append:
# | Out-File -FilePath C:\Users\$env:UserName\Desktop\FileName.txt 
# in order to maintain a paper trail / run diffs.
Get-MsolUser -All | Where-Object {
  $_.isLicensed -eq "TRUE" -and $_.Licenses.AccountSKUID -eq $targetSkus.RemoveLicenses
} | 
Select-Object Displayname,UserPrincipalName,isLicensed,Licenses

# Change the license assignment for a single account:
Set-MsolUserLicense -UserPrincipalName "user@domain.com" @targetSkus

# Change the license assignment for all accounts:
Get-MsolUser -All | Where-Object {
  $_.isLicensed -eq "TRUE" -and $_.Licenses.AccountSKUID -eq $targetSkus.RemoveLicenses
} | 
Set-MsolUserLicense @targetSkus

<#

If you receive the following error after attempting the swap:
'Set-MsolUserLicense: The license domain:ENTERPRISEPACK is not valid. To find a list of valid licenses..'
It's because the user already has the license applied to them. You can verify with:
(Get-MsolUser -UserPrincipalName "user@domain.com").licenses or by checking the output of #L29-32

Lastly, I like to re-run some of the previous steps to verify everything is good:

Run #L35-L38 again to verify target SKU was removed from all users. Should return an empty line.
Run #L35-L38, switching out the hash value with '.AddLicenses', to verify target SKU was added to all users.
Run #L29 again to verify 'ConsumedUnits' counts.

#>
