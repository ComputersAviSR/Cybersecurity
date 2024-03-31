<################################################################################>
# SYNOPSIS                                                                      #
# This script is designed to authenticate and fetch all the managed accounts    #
# using BeyondTrust API.                                                        #
#                                                                               #
# DESCRIPTION                                                                   #
# The script uses predefined API key and user credentials to authenticate       #
# against the BeyondTrust API and fetches all the managed accounts.             #
#                                                                               #
# VERSION                                                                       #
# 1.1.1                                                                         #
#                                                                               #
# .BUILD                                                                        #
# Build:                                                                        #
#                                                                               #
# PURPOSE                                                                       #
# To automate the process of fetching all the managed account details           #
# from BeyondTrust and exporting them to a single Excel file with multiple      #
# sheets.                                                                       #
#                                                                               #
<################################################################################>

# API CALLS THAT ARE USED IN THIS SCRIPT

# GET SmartRules/{ID}/Assets --> This is for Managed Accounts
# GET ManagedSystems
# GET Devices

# Define API key and username
$baseURL = Read-Host "Provide Cloud API URL --> "
$apiKey = Read-Host "Provide API Key --> "
$user = Read-Host "Provide LogIn user (This should have access to the API Key) --> "
$locUser = Read-Host "Location to Store your files --> "

# Corrected headers with password included as per the guide
$headers = @{
    "Authorization" = "PS-Auth key=$apiKey; runas=$user;"
}

# Function to authenticate and fetch managed accounts
function AuthenticateAndFetchManagedAccounts {
    $uri = "$baseURL/Auth/SignAppin"

    try {
        # Authenticate
        $signinResult = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -SessionVariable script:session
        Write-Host "Authentication successful"
    } 
    catch {
        Write-Host "Error occurred during authentication: $_"
        return
    }

    # Categories offered by BeyondTrust
    $categories = @(
        "Devices",
        "Managed Accounts",
        "Managed Systems"
    )

    # Let user select categories
    $selectedCategories = Read-Host "Select categories from the following options: $($categories -join ', ')"
    $selectedCategories = $selectedCategories.Split(",") | ForEach-Object { $_.Trim() }

    # Create a new Excel workbook
    $excelFilePath = "$locUser\Accounts.xlsx"
    $excel = New-Object -ComObject Excel.Application
    $workbook = $excel.Workbooks.Add()

    foreach ($category in $selectedCategories) {
        try {
            if ($category -eq "Managed Accounts") {
                # For Managed Accounts, fetch Smart Rules to get SmartRule IDs
                $smartRules = Invoke-RestMethod -Uri "$baseURL/SmartRules" -Method GET -Headers $headers -WebSession $session
                $smartRules | Export-Csv -Path "$locUser\smartRules.csv" -NoTypeInformation
                # Import Smart Rules from CSV and fetch Managed Accounts using SmartRule IDs
                $importedSmartRules = Import-Csv -Path "$locUser\smartRules.csv"
                foreach ($rule in $importedSmartRules) {
                    if ($rule.category -eq "Managed Accounts") {
                        $smartRuleID = $rule.SmartRuleID
                        $smartRuleTitle = $rule.Title
                        $managedAccounts = Invoke-RestMethod -Uri "$baseURL/SmartRules/$smartRuleID/ManagedAccounts" -Method GET -Headers $headers -WebSession $session
                        if ($managedAccounts) {
                            foreach ($account in $managedAccounts) {
                                $account | Add-Member -MemberType NoteProperty -Name "SmartRuleTitle" -Value $smartRuleTitle -Force
                            }
                            $allmanagedAccounts += $managedAccounts
                            #Write-Host "Managed Accounts for Smart Rule '$smartRuleID' exported to CSV."
                        } else {
                            #Write-Host "No Managed Accounts found for Smart Rule '$smartRuleID'"
                        }
                    }
                }
                $uniqueManagedAccounts = $allmanagedAccounts | Sort-Object -Property ManagedAccountID -Unique
                #$uniqueManagedAccounts| Export-Csv -Path "C:\Users\Avi(WORK)\Desktop\Output BeyondTrust\ManagedAccounts.csv" -Append -NoTypeInformation
                
 
                if ($uniqueManagedAccounts) {
                    # Add managed accounts to the Excel workbook as a new sheet
                    $sheet = $workbook.Sheets.Add()
                    $sheet.Name = $category
                    
                    $row = 1
                    $column = 1 # Initialize column index
                    # Export column names as the first row
                    foreach ($property in $uniqueManagedAccounts[0].PSObject.Properties) {
                        $sheet.Cells.Item($row, $column) = $property.Name
                        $column++
                    }
                    
                    $row++
                    # Export data starting from the second row
                    foreach ($account in $uniqueManagedAccounts) {
                        $column = 1 # Reset column index for each row
                        foreach ($property in $account.PSObject.Properties) {
                            $sheet.Cells.Item($row, $column) = $property.Value
                            $column++
                        }
                        $row++
                    }
                    Write-Host "Managed Accounts exported"
                } else {
                    Write-Host "No Managed Accounts found for category '$category'"
                }
                # Delete the Smart Rules CSV file
                Remove-Item -Path "$locUser\smartRules.csv" -Force
            } else {
                # For other categories (Assets and Managed Systems), directly fetch Managed Accounts
                $clearCategory = $category -replace '\s+',''
                $managedAccounts = Invoke-RestMethod -Uri "$baseURL/$clearCategory" -Method GET -Headers $headers -WebSession $session
                if ($managedAccounts) {
                    # Add managed accounts to the Excel workbook as a new sheet
                    $sheet = $workbook.Sheets.Add()
                    $sheet.Name = $category
                    
                    $row = 1
                    $column = 1 # Initialize column index
                    # Export column names as the first row
                    foreach ($property in $managedAccounts[0].PSObject.Properties) {
                        $sheet.Cells.Item($row, $column) = $property.Name
                        $column++
                    }
                    
                    $row++
                    # Export data starting from the second row
                    foreach ($account in $managedAccounts) {
                        $column = 1 # Reset column index for each row
                        foreach ($property in $account.PSObject.Properties) {
                            $sheet.Cells.Item($row, $column) = $property.Value
                            $column++
                        }
                        $row++
                    }
                    Write-Host "Managed $category exported."
                } else {
                    Write-Host "No Managed $category found"
                }
            }
        } 
        catch [System.Net.WebException] {
            Write-Host "Error occurred while fetching accounts for category '$category': $_"
        }
    }

    # Save and close the Excel workbook
    $workbook.SaveAs($excelFilePath)
    $excel.Quit()
    Write-Host "Excel workbook saved at $excelFilePath"
}

# Call the function to authenticate and fetch Managed Accounts
AuthenticateAndFetchManagedAccounts
