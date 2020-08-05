# Customer Subscription Report

Scripts and stuff for Microsoft Partners who need to compile reports on Customer data.

## Get-AllCustomerSubscriptions

This script is typically used when a Microsoft CSP Partner wants to transfer their billing and needs to efficiently compile a subscription report.
By logging into the target Microsoft Partner tenant (parent), a list of all associated Customers (children), their subscriptions, and MSRP pricing is generated.

Some things to take into consideration: 
- The account being logged into must have the Admin agent role assigned in the corresponding Partner Center (just Global Admin might work, too).
- The subscriptions logged can be from any source (e.g. Microsoft directly, Reseller/CSP, OL/VL, etc.) and the Partner tenant is not included.
- The script references SKU lists that /should/ be up-to-date, but this stuff changes all the time. If something needs changing, submit a PR!
- If a price cell is blank, it's likely because the product is not available via the CSP program, or no longer exists.