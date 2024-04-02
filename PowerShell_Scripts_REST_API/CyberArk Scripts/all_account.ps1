###################################################################
#              Name : Avi Singh Rathore                           #
#              Date : 21/09/2023                                  #
#           Version : 1.0 (Final)                                 #
#           Details : Store all the accounts in a single file     #
###################################################################

#Install-Module -Name psPAS -Scope CurrentUser
#or
#Install-Module -Name psPAS

# Definition of Authentication Methods, Getting Login Credential & URL and Storage Location
$clientURI = Read-Host "Enter the PVWA URL --> "
$authtype = Read-Host "Enter type of Authentication (LDAP, CYBERARK)"
$passStorage = Read-Host "Location for Storing Account Details -> "
$cred = Get-Credential

# Global Variables
$allSafes = @()
$allAccounts = @()
$perAccountFields = @()
$allSafeNames = @()
$userids = @()
$userPassword = @()
$PasswordCSV = @()
$perPassword = @()
$perPasswordString = @()
$allpass = @()

try{

    # Creating a new Session with VAULT
    New-PASSession -Credential $cred -BaseURI $clientURI -type $authtype
  
    # Fetch all the available accounts and store them into an array
    $allAccounts = Get-PASAccount

    # Iterating through an array and adding a new column for Passwords linked to individual Accounts
    # Column will fetch & display individual password fields for a specific Account ID 
    foreach($value in $allAccounts){
        $AccountID = $value.id
        $perPassword =  Get-PASAccountPassword -AccountID $AccountID -Reason "Testing"
        $value| Add-Member -MemberType NoteProperty -Name Password -Value $perPassword.Password
    }
    
    # Exporting the file into a csv format
    $allAccounts | ConvertTo-Csv | Out-File "$passStorage\All Account Details.csv"

    Write-Host "-------------------------- Process Ended Successfully -----------------------------"

}

catch {
    Write-Host "An Exception has occured / Re-run the script with correct details"
}