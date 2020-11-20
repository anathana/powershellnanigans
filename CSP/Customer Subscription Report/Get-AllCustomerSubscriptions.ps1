<# 
============================
Get-AllCustomerSubscriptions
============================
This script is typically used when a Microsoft CSP Partner wants to transfer their billing and needs to efficiently compile a subscription report.
By logging into the target Microsoft Partner tenant (parent), a list of all associated Customers (children), their subscriptions, and MSRP pricing is generated.

Some things to take into consideration: 
    - The account being logged into must have the Admin agent role assigned in the corresponding Partner Center (just Global Admin might work, too).
    - The subscriptions logged can be from any source (e.g. Microsoft directly, Reseller/CSP, OL/VL, etc.) and the Partner tenant is not included.
    - The script references SKU lists that /should/ be up-to-date, but this stuff changes all the time. If something needs changing, submit a PR!
    - If a price cell is blank, it's likely because the product is not available via the CSP program, or no longer exists.
#>

# Get current SKU Map
$skuGet = Invoke-WebRequest https://raw.githubusercontent.com/vthn/powershellnanigans/master/CSP/Customer%20Subscription%20Report/skuMap.txt
$skuObj = $skuGet.Content
$skuMap = ConvertFrom-StringData -StringData $skuObj

# Get current Price Map
$priceGet = Invoke-WebRequest https://raw.githubusercontent.com/vthn/powershellnanigans/master/CSP/Customer%20Subscription%20Report/priceMap.txt
$priceObj = $priceGet.Content
$priceMap = ConvertFrom-StringData -StringData $priceObj

# Convert SKU ID to Offer Display Name
function TranslateSku($subSku)
{
    $delimiter = $subSku.IndexOf(":")
    $subSku = $subSku.Substring($delimiter+1)

    if ($skuMap.ContainsKey($subSku) -ne $true)
    {
        return $subSku
    }
    
    return $skuMap[$subSku]
}

# Match SKU ID to Price
function MatchPrice($subSku)
{
    $delimiter = $subSku.IndexOf(":")
    $subSku = $subSku.Substring($delimiter+1)

    if ($priceMap.ContainsKey($subSku) -ne $true)
    {
        return $subSku
    }
    
    return $priceMap[$subSku]
}

# Sign-in to the CSP Partner tenant you want to pull Customer data from (Partner Relationship and Delegated Admin access must be established)
Connect-MsolService
$partnerName = $((Get-MsolCompanyInformation).displayname)
$customers = Get-MsolPartnerContract -All
Start-Transcript -Path .\$partnerName\log.txt
Write-Host "Found $($customers.Count) customers for $partnerName." -ForegroundColor DarkGreen
$CSVpath = ".\$partnerName\$partnerName-Customer-report.csv"
  
foreach ($customer in $customers) {
    Write-Host "Retrieving license info for $($customer.name)" -ForegroundColor Green

    # Get the list subscriptions and their respective seat counts in the tenant
    $skuList = Get-MsolAccountSku -TenantId $customer.TenantId
    foreach ($sku in $skuList) {
        Write-Host "$($sku.AccountSkuId)" -ForegroundColor Yellow
        $tenantSkuList = [pscustomobject][ordered]@{
            CustomerName      = $customer.Name
            Domain            = $customer.DefaultDomainName
            TenantId          = $customer.TenantId
            Product           = $(TranslateSku($sku.AccountSkuId))
            Assigned          = $sku.ConsumedUnits
            Total             = $sku.ActiveUnits
            MSRP              = $(MatchPrice($sku.AccountSkuId))
        }
        $tenantSkuList | Export-CSV -Path $CSVpath -Append -NoTypeInformation   
    }
}

Stop-Transcript
