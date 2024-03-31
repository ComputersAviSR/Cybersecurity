<################################################################################>
# SYNOPSIS                                                                      #
# This script is designed to authenticate and fetch Managed Accounts from       #
# BeyondTrust API.                                                              #
#                                                                               #
# DESCRIPTION                                                                   #
# The script uses predefined API key and user credentials to authenticate       #
# against the BeyondTrust API and fetches the list of managed accounts.         #
#                                                                               #
#                                                                               #
# VERSION                                                                       #
# 1.1.1                                                                         #
#                                                                               #
# .BUILD                                                                        #
# Build:                                                                        #
#                                                                               #
# PURPOSE                                                                       #
# To automate the process of fetching managed account details from BeyondTrust  #
# and exporting them to a CSV file for further analysis.                        #
#                                                                               #
<################################################################################>


# Define API key and username
$baseURL = Read-Host "Provide Cloud API URL --> "
$apiKey = Read-Host "Provide API Key --> "
$user = Read-Host "Provide LogIn user (This should have access to the API Key) --> "
$locUser = Read-Host "Location to Store your files --> "

# Corrected headers with password included as per the guide
$headers = @{
    "Authorization" = "PS-Auth key=$apiKey; runas=$user; pwd=[RentDell1!RentDell1!]"
}

# Function to authenticate and fetch users
function AuthenticateAndFetchUsers {
    $uri1 = "$baseURL/Auth/SignAppin"

    try {
        # Authenticate
        $signinResult = Invoke-RestMethod -Uri $uri1 -Method POST -Headers $headers -SessionVariable script:session
        Write-Host "Authentication successful"
    } 
    catch {
        Write-Host "Error occurred during authentication: $_"
        if ($_.Exception.Response) {
            $errorResponse = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd()
            Write-Host "Response Body: $responseBody"
        }
        return
    }

    # Define URI for getting users
    $uri2 = "$baseURL/SmartRules"

    try {
        # Fetch users using the authenticated session
        $usersResult = Invoke-RestMethod -Uri $uri2 -Method GET -Headers $headers -WebSession $session
        Write-Host "Smart Rules fetched successfully"
        # Export users to CSV
        $usersResult | Export-Csv -Path "$locUser" -NoTypeInformation
        Write-Host "Smart Rules exported to users.csv"
    } catch {
        Write-Host "Error occurred while fetching users: $_"
    }
}

# Call the function to authenticate and fetch users
AuthenticateAndFetchUsers