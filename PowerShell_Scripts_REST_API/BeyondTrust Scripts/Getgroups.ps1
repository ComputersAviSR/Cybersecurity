<################################################################################>
# SYNOPSIS                                                                      #
# This script is designed to authenticate and fetch groups from                 #
# BeyondTrust API.                                                              #
#                                                                               #
# DESCRIPTION                                                                   #
# The script uses predefined API key and user credentials to authenticate       #
# against the BeyondTrust API and fetches the list of groups.                   #
#                                                                               #
#                                                                               #
# VERSION                                                                       #
# 1.1.1                                                                         #
#                                                                               #
# .BUILD                                                                        #
# Build:                                                                        #
#                                                                               #
# PURPOSE                                                                       #
# To automate the process of fetching groups details from BeyondTrust           #
# and exporting them to a CSV file for further analysis.                        #
#                                                                               #
<################################################################################>


# Define API key and username
$baseURL = Read-Host "Provide Cloud API URL --> "
$apiKey = Read-Host "Provide API Key --> "
$user = Read-Host "Provide LogIn user (This should have access to the API Key) --> "
$locUser = Read-Host "Location to Store your files --> "

$headers = @{
    "Authorization" = "PS-Auth key=$apiKey; runas=$user;"
}

# Function to authenticate and fetch groups
function AuthenticateAndFetchGroups {
    $uri1 = "$baseURL/Auth/SignAppin"

    try {
        $signinResult = Invoke-RestMethod -Uri $uri1 -Method POST -Headers $headers -SessionVariable script:session
        Write-Host "Authentication Successful"
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

    # Define URI for getting groups
    $uri2 = "$baseURL/UserGroups"

    try {
        # Invoke API to get groups
        $groupsResult = Invoke-RestMethod -Uri $uri2 -Method GET -Headers $headers -WebSession $session
        Write-Host "Groups fetched successfully"
        # Export groups to CSV
        $groupsResult | Export-Csv -Path "$locUser" -NoTypeInformation
        Write-Host "Groups exported to groups.csv"
    } catch {
        Write-Host "Error occurred while fetching groups: $_"
    }
}

AuthenticateAndFetchGroups