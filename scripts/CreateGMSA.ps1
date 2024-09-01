$ErrorActionPreference = 'STOP'
# Define variables
$gMSAName = "PacketP_gMSA" # Replace with your gMSA name
$domain = "PacketPunisher.com" # Replace with your domain
$groupName = "gMSA_Admins" # Replace with your group name
$groupPath = "OU=Domain Service Accounts,DC=PacketPunisher,DC=com"  # Replace with your domain path
$allowedComputer = 'CN=WIN11-KVM-VM,OU=Domain Computers,DC=PacketPunisher,DC=com'

# Step 1: Verify if a KDS Root Key exists
$kdsRootKey = Get-KdsRootKey

if (-not $kdsRootKey) {
    Write-Host "No KDS Root Key found. Creating a new KDS Root Key... with
    # Creates a KDS root key with immediate effect (approximately 10 hours delay)
    Add-KdsRootKey -Effective
    "
} else {
    Write-Host "KDS Root Key already exists."
}

# Step 2: Create the Security Group
if (-not (Get-ADGroup -Filter {Name -eq $groupName})) {
    Write-Host "Creating the security group $groupName..."
    New-ADGroup -Name $groupName -SamAccountName $groupName -GroupCategory Security -GroupScope Global -DisplayName $groupName -Path $groupPath
    Write-Host "Security group $groupName created."
} else {
    Write-Host "Security group $groupName already exists."
}

# Step 3: Create the gMSA Account
if (-not (Get-ADServiceAccount -Filter {Name -eq $gMSAName})) {
    Write-Host "Creating the gMSA account $gMSAName..."
    New-ADServiceAccount -Name $gMSAName -DNSHostName "$gMSAName.$domain" -PrincipalsAllowedToRetrieveManagedPassword $groupName
    Set-ADServiceAccount -Identity 'PacketP_gMSA$' -PrincipalsAllowedToRetrieveManagedPassword $allowedComputer
    Write-Host "gMSA account $gMSAName created."
} else {
    Write-Host "gMSA account $gMSAName already exists."
}

# Step 4: Install the gMSA on the Target Server
Write-Host "Installing the gMSA account $gMSAName on the target server..."
Install-ADServiceAccount -Identity $gMSAName -
Write-Host "gMSA account $gMSAName installed on the target server."

# Step 5: Verify the gMSA Installation
Write-Host "Verifying the gMSA account $gMSAName installation..."
if (Test-ADServiceAccount -Identity $gMSAName) {
    Write-Host "gMSA account $gMSAName is successfully installed and verified."
} else {
    Write-Host "gMSA account $gMSAName installation failed. Please check for errors."
}
