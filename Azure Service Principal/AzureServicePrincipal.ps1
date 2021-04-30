#apply Service Pricipal to whole subscription
$scope = "/subscriptions/$(Get-AzSubscription)"

# Generate Password, make sure you note down the password, not recoverable!
Add-Type -AssemblyName 'System.Web'
$password = [System.Web.Security.Membership]::GeneratePassword(24, 6)
$password

# Create AES-256 key file
$KeyFile = "c:\Temp\aes.key"
$Key = New-Object Byte[] 32
[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key)
$Key | out-file $KeyFile

# Secure The password
$PasswordFile = "c:\Temp\password.bin"
$KeyFile = "c:\Temp\aes.key"
# $password = ""
$Key = Get-Content $KeyFile
$Password = $password | ConvertTo-SecureString -AsPlainText -Force
$Password | ConvertFrom-SecureString -key $Key | Out-File $PasswordFile

# Create the Password Credential Object
[Microsoft.Azure.Commands.ActiveDirectory.PSADPasswordCredential]`
    $PasswordCredential = @{
    StartDate = Get-Date;
    EndDate   = (Get-Date).AddYears(5);
    Password  = $password
}
$PasswordCredential 

# Create the Service Principal with a Password Credential
$sp = New-AzAdServicePrincipal `
    -DisplayName "ScriptCredentials" `
    -PasswordCredential $PasswordCredential
$sp

#assign Scope and Roles
New-AzRoleAssignment -ApplicationId $sp.ApplicationId `
    -Scope $scope `
    -RoleDefinitionName "Contributor"

# Create Credential
$TenantID = ""
$user = "http://ScriptCredentials"
$PasswordFile = "c:\Temp\password.bin"
$KeyFile = "c:\Temp\aes.key"
$key = Get-Content $KeyFile
$credential = New-Object -TypeName System.Management.Automation.PSCredential `
 -ArgumentList $User, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)
# $credential | Export-CliXml -Path 'C:\Temp\cred.xml'

# Login Azure
Connect-AzAccount -ServicePrincipal -Credential $credential -Tenant $TenantID