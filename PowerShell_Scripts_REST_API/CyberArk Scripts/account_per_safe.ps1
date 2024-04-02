###################################################################
#              Name : Avi Singh Rathore                           #
#              Date : 21/09/2023                                  #
#           Version : 1.0 (Final)                                 #
#           Details : Accounts information as per safes           #
###################################################################

#Install-Module -Name psPAS -Scope CurrentUser
#or
#Install-Module -Name psPAS

# Definition of Authentication Methods, Getting Login Credential & URL
$clientURI = Read-Host "Enter the PVWA URL --> "
$authtype = Read-Host "Enter type of Authentication (LDAP, CYBERARK)"
$passStorage = Read-Host "Location for Storing Account Details -> "
$cred = Get-Credential

# Global Variables
$allSafes = @()
$allAccounts = @()
$allSafeNames = @()
$userids = @()
$userPassword = @()
$PasswordCSV = @()

# Try Block 
try {

    # Creating a new Session with VAULT with a specific authentication type selected by the user on the go
    New-PASSession -Credential $cred -BaseURI $clientURI -type $authtype
    #Get-PASLoggedOnUser

    # Fetch all the Safes that are there in the System
    $allSafes = Get-PASSafe

    foreach($valueSafe in $allSafes){
            
            $safeName = $valueSafe.safeName
            $allSafeNames += $safeName
            
    }

    Write-Host "Processing"
    for ($x = 0; $x -lt $allSafeNames.Count; $x++) {
        
        # Fetch all the available accounts as per the current safe and store them into an array
        $indvSafes = $allSafeNames[$x]
        
        # Get all the account from the specific safe and store them in an array format to futher process
        $allAccounts = Get-PASAccount -safeName $indvSafes
        
        # Iterating through an array and adding a new row for Passwords linked to individual Accounts
        foreach($acc in $allAccounts){
            
            $Accountid = $acc.id
            $perPassword =  Get-PASAccountPassword -AccountID $AccountID -Reason "Testing"
            $acc| Add-Member -MemberType NoteProperty -Name Password -Value $perPassword.Password
            
        }
        
        # Exporting the file into a csv format
        $allAccounts | ConvertTo-Csv | Out-File "$passStorage\$indvSafes.csv"
        
        Write-Host "---------------------- $indvSafes Safe Processing || Ended Successfully -------------------------"

    }
}

# Catch Block
catch {
    Write-Host "An Exception has occured / Re-run the script with correct details"
}