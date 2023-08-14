<#

.SYNOPSIS
    Get-AzureADUsers PowerShell script.

.DESCRIPTION
    Get-AzureADUsers.ps1 is a PowerShell script retrieves Azure AD users with their last sign in date.

.AUTHOR:
    Mohammad Zmaili

.EXAMPLE
    .\Get-AzureADUsers.ps1
      Retrieves all Azure AD users with their last sign in date.

Important Notes:
    > Make sure to have 'c:\temp' folder
    
    > If 'Last Success Signin (UTC)' value is 'N/A', this could be due to one of the following two reasons:
        - The last successful sign-in of a user took place before April 2020.
        - The affected user account was never used for a successful sign-in.
        
#>


function Connect-AzureDevicelogin {
    [cmdletbinding()]
    param( 
        [Parameter()]
        $ClientID = '1950a258-227b-4e31-a9cf-717495945fc2',
        
        [Parameter()]
        [switch]$Interactive,
        
        [Parameter()]
        $TenantID = 'common',
        
        [Parameter()]
        $Resource = "https://graph.microsoft.com/",
        
        # Timeout in seconds to wait for user to complete sign in process
        [Parameter(DontShow)]
        $Timeout = 1
        #$Timeout = 300
    )
try {
    $DeviceCodeRequestParams = @{
        Method = 'POST'
        Uri    = "https://login.microsoftonline.com/$TenantID/oauth2/devicecode"
        Body   = @{
            resource  = $Resource
            client_id = $ClientId
            redirect_uri = "https://login.microsoftonline.com/common/oauth2/nativeclient"
        }
    }
    $DeviceCodeRequest = Invoke-RestMethod @DeviceCodeRequestParams
 
    # Copy device code to clipboard
    $DeviceCode = ($DeviceCodeRequest.message -split "code " | Select-Object -Last 1) -split " to authenticate."
    Set-Clipboard -Value $DeviceCode

    Write-Host ''
    Write-Host "Device code " -ForegroundColor Yellow -NoNewline
    Write-Host $DeviceCode -ForegroundColor Green -NoNewline
    Write-Host "has been copied to the clipboard, please paste it into the opened 'Microsoft Graph Authentication' window, complete the sign in, and close the window to proceed." -ForegroundColor Yellow
    Write-Host "Note: If 'Microsoft Graph Authentication' window didn't open,"($DeviceCodeRequest.message -split "To sign in, " | Select-Object -Last 1) -ForegroundColor gray

    # Open Authentication form window
    Add-Type -AssemblyName System.Windows.Forms
    $form = New-Object -TypeName System.Windows.Forms.Form -Property @{ Width = 440; Height = 640 }
    $web = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{ Width = 440; Height = 600; Url = "https://www.microsoft.com/devicelogin" }
    $web.Add_DocumentCompleted($DocComp)
    $web.DocumentText
    $form.Controls.Add($web)
    $form.Add_Shown({ $form.Activate() })
    $web.ScriptErrorsSuppressed = $true
    $form.AutoScaleMode = 'Dpi'
    $form.text = "Microsoft Graph Authentication"
    $form.ShowIcon = $False
    $form.AutoSizeMode = 'GrowAndShrink'
    $Form.StartPosition = 'CenterScreen'
    $form.ShowDialog() | Out-Null
        
    $TokenRequestParams = @{
        Method = 'POST'
        Uri    = "https://login.microsoftonline.com/$TenantId/oauth2/token"
        Body   = @{
            grant_type = "urn:ietf:params:oauth:grant-type:device_code"
            code       = $DeviceCodeRequest.device_code
            client_id  = $ClientId
        }
    }
    $TimeoutTimer = [System.Diagnostics.Stopwatch]::StartNew()
    while ([string]::IsNullOrEmpty($TokenRequest.access_token)) {
        if ($TimeoutTimer.Elapsed.TotalSeconds -gt $Timeout) {
            throw 'Login timed out, please try again.'
        }
        $TokenRequest = try {
            Invoke-RestMethod @TokenRequestParams -ErrorAction Stop
        }
        catch {
            $Message = $_.ErrorDetails.Message | ConvertFrom-Json
            if ($Message.error -ne "authorization_pending") {
                throw
            }
        }
        Start-Sleep -Seconds 1
    }
    Write-Output $TokenRequest.access_token
}
finally {
    try {
        Remove-Item -Path $TempPage.FullName -Force -ErrorAction Stop
        $TimeoutTimer.Stop()
    }
    catch {
        #Ignore errors here
    }
}
}

Function ConnecttoAzureAD{
    Write-Host ''
    Write-Host "Checking if there is a valid Access Token..." -ForegroundColor Yellow
    $headers = @{ 
                'Content-Type'  = "application\json"
                'Authorization' = "Bearer $global:accesstoken"
                }
    $GraphLink = "https://graph.microsoft.com/v1.0/domains"
    $GraphResult=""
    $GraphResult = (Invoke-WebRequest -Headers $Headers -Uri $GraphLink -UseBasicParsing -Method "GET" -ContentType "application/json").Content | ConvertFrom-Json

    if($GraphResult.value.Count)
    {
            $headers = @{ 
            'Content-Type'  = "application\json"
            'Authorization' = "Bearer $global:accesstoken"
            }
            $GraphLink = "https://graph.microsoft.com/v1.0/me"
            $GraphResult=""
            $GraphResult = (Invoke-WebRequest -Headers $Headers -Uri $GraphLink -UseBasicParsing -Method "GET" -ContentType "application/json").Content | ConvertFrom-Json
            $User_DisplayName=$GraphResult.displayName
            $User_UPN=$GraphResult.userPrincipalName
            Write-Host "There is a valid Access Token for user: $User_DisplayName, UPN: $User_UPN" -ForegroundColor Green

    }else{
        Write-Host "There no valid Access Token, please sign-in to get an Access Token" -ForegroundColor Yellow
        $global:accesstoken = Connect-AzureDevicelogin
        ''
        if ($global:accesstoken.Length -ge 1){
            $headers = @{ 
            'Content-Type'  = "application\json"
            'Authorization' = "Bearer $global:accesstoken"
            }
            $GraphLink = "https://graph.microsoft.com/v1.0/me"
            $GraphResult=""
            $GraphResult = (Invoke-WebRequest -Headers $Headers -Uri $GraphLink -UseBasicParsing -Method "GET" -ContentType "application/json").Content | ConvertFrom-Json
            $User_DisplayName=$GraphResult.displayName
            $User_UPN=$GraphResult.userPrincipalName
            Write-Host "You signed-in successfully, and got an Access Token for user: $User_DisplayName, UPN: $User_UPN" -ForegroundColor Green
        }
    }

}

''
'========================================================'
Write-Host '            Azure AD Users Last SignIn Report          ' -ForegroundColor Green 
'========================================================'
''
$RetreivedUsers=0
$headers = @{ 
            'Content-Type'  = "application\json"
            'Authorization' = "Bearer $global:accesstoken"
            }

$GraphLink = "https://graph.microsoft.com/beta/users?$"
$GraphLink = $GraphLink + "select=id,userPrincipalName,displayName,accountEnabled,onPremisesSyncEnabled,createdDateTime&`$top=999"

do{
    try{
        $AADUsers = @()
        $ADUserep=@()
        $ADUseresult = Invoke-WebRequest -Headers $Headers -Uri $GraphLink -UseBasicParsing -Method "GET" -ContentType "application/json"
    }catch{
        Write-Host ''
        Write-Host ''
        Write-Host "Operation aborted. Please make sure that tenant has an Azure Active Directory Premium license, and you have the right permissions." -ForegroundColor red -BackgroundColor Black
        Write-Host ''
        Write-Host "Script completed successfully." -ForegroundColor Green -BackgroundColor Black
        Write-Host ''
        exit
    }
    $ADUseresult = $ADUseresult.Content | ConvertFrom-Json
        if ($ADUseresult.value) {
            $AADUsers += $ADUseresult.value
        }
        else {
            $AADUsers += $ADUseresult
        }

        foreach($ADUser in $AADUsers){
            $ADUserepobj = New-Object PSObject
            $ADUserepobj | Add-Member NoteProperty -Name "Object ID" -Value $ADUser.id
            $ADUserepobj | Add-Member NoteProperty -Name "Display Name" -Value $ADUser.displayName
            $ADUserepobj | Add-Member NoteProperty -Name "User Principal Name" -Value $ADUser.userPrincipalName
            if ($ADUser.accountEnabled){$ADUserepobj | Add-Member NoteProperty -Name "Account Enabled" -Value $ADUser.accountEnabled}else{$ADUserepobj | Add-Member NoteProperty -Name "Account Enabled" -Value "False"}
            if ($ADUser.onPremisesSyncEnabled){$ADUserepobj | Add-Member NoteProperty -Name "onPremisesSyncEnabled" -Value $ADUser.onPremisesSyncEnabled}else{$ADUserepobj | Add-Member NoteProperty -Name "onPremisesSyncEnabled" -Value "False"}
            $ADUserepobj | Add-Member NoteProperty -Name "Created DateTime (UTC)" -Value $ADUser.createdDateTime
            if (($ADUser.signInActivity).lastSignInDateTime) {$ADUserepobj | Add-Member NoteProperty -Name "Last Success Signin (UTC)" -Value ($ADUser.signInActivity).lastSignInDateTime}else{$ADUserepobj | Add-Member NoteProperty -Name "Last Success Signin (UTC)" -Value "N/A"}
            $ADUserep += $ADUserepobj
        }

        $ADUserep | Export-Csv -path C:\temp\AzureADUsers.csv -NoTypeInformation -Append
        $RetreivedUsers += $ADUserep.Count
        Write-Host "Retreving AAD Users..."

        $GraphLink = ($ADUseresult).'@odata.nextlink'
  } until (!($GraphLink)) 



''
Write-Host "==================================="
Write-Host "|Retreived Azure AD Users Summary:|"
Write-Host "==================================="
Write-Host "Number of retreived AAD Users:" $RetreivedUsers
''
Write-host "The report has been created under the pathC:\temp\AzureADUsers.csv" -ForegroundColor green

''
''
Write-Host "Script completed successfully." -ForegroundColor Green -BackgroundColor Black
''