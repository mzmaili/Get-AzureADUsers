# Get-AzureADUsers
Coming from the fact that we have a challenge when it comes to downloading the full list of Azure AD users from Azure AD portal if you have large number of users as this attribute is not available either in AzureAD or MSOnline modules, Get-AzureADUsers.ps1 PowerShell script resolves this challenge as it retrieves Azure AD users with their last sign in date.

## Script requirements
- Make sure to have 'c:\temp' folder

## How to run the script
Download and run the `Get-AzureADUsers.ps1` script from [this](https://github.com/mzmaili/Get-AzureADUsersLastSignIn) GitHub repo. 

## Why is this script useful?
- To retrieve Azure AD users with their last sign-in details.
- To generate a CSV report with the result.

## User experience
PowerShell console output:  
![Alt text](https://github.com/mzmaili/Get-AzureADUsersLastSignIn/blob/main/media/PS.png "PowerShell Output")  

CSV output:  
![Alt text](https://github.com/mzmaili/Get-AzureADUsersLastSignIn/blob/main/media/CSV.png "CSV Output")  

# Frequently asked questions
## Does this script change anything?
No. It just retrieves data.

## Should tenant have a specific Azure AD license?
No, its enough to have Azure AD free license.

## What data does this script retrieves?
Get-AzureADUsersLastSignIn script retrieves the following details for each user in the tenant:  
`Object ID, Display Name, User Principal Name, Account Enabled, onPremisesSyncEnabled, Created DateTime (UTC), Last Success Signin (UTC)`

## Does this script require any PowerShell module to be installed?
No, the script does not require any PowerShell module.

