function Get-TSAFileAccess {
    [CmdletBinding()]
    param (
        [string]$Path,
        $sAMAccountName,
        $Domain,
        $RequiredFileSystemRight
    )
    
    begin {
        $ErrorActionPreference = 'STOP'
        # variables
        $DomainUser = "${Domain}\${sAMAccountName}"
        $Access = (Get-Acl $Path).Access

        # check local group permission groups
        $LocalGroupMembership = (Get-LocalGroup | Where-Object {$DomainUser -in (Get-LocalGroupMember $_).Name}).Name

        # check domain group permissiosn using ldap
        function ldap_find_all ($query) {(New-Object DirectoryServices.DirectorySearcher("$query")).FindAll()}

        # get distinguished name based on SamAccountName
        [string]$DistinguishedName = (ldap_find_all -query "(sAMAccountName=${sAMAccountName})")[0].Properties.distinguishedname

        #$DomainGroupMembership = ldifde -f file.ldf -d "dc=memnon,dc=local" -r "(member:1.2.840.113556.1.4.1941:=cn=PAMService,CN=Managed Service Accounts,DC=memnon,DC=local)"
        $DomainGroupMembership =  (ldap_find_all -query "(member:1.2.840.113556.1.4.1941:=$DistinguishedName)").Properties.name
        $DomainGroupMembership = foreach ($group in $DomainGroupMembership) {"${Domain}\${group}"}

        $ObjectMatches = @()

        # iterating only over the items with permissiosn set on the $Path
        switch ($Access) {
            # explicit acl definition
            {$_.IdentityReference.Value -eq "${DomainUser}"} {
                #Write-Host "$($_.IdentityReference.Value) -Matched !" -ForegroundColor Green
                $ObjectMatches += [PSCustomObject]@{
                    Path = $Path
                    User = $_.IdentityReference.Value
                    ActualFileSystemRight = $_.FileSystemRights
                    RequiredFileSystemRight = $RequiredFileSystemRight
                }

                foreach ($right in $ObjectMatches[-1].RequiredFileSystemRight) {
                    if ($ObjectMatches[-1].ActualFileSystemRight -contains $right) {Write-Host "$($_.IdentityReference.Value) does provide ${right} for path`n`t$Path" -ForegroundColor Green}
                }
            }
            # local group acl definition
            {($_.IdentityReference.Value -split '\\')[-1] -in $LocalGroupMembership} {
                #Write-Host "$($_.IdentityReference.Value) -Matched !" -ForegroundColor Green
                $ObjectMatches += [PSCustomObject]@{
                    Path = $Path
                    User = $_.IdentityReference.Value
                    ActualFileSystemRight = $_.FileSystemRights
                    RequiredFileSystemRight = $RequiredFileSystemRight
                }

                foreach ($right in $ObjectMatches[-1].RequiredFileSystemRight) {
                    if ($ObjectMatches[-1].ActualFileSystemRight -contains $right) {Write-Host "$($_.IdentityReference.Value) does provide ${right} for path`n`t$Path" -ForegroundColor Green}
                }
            }
            # domain group acl definition
            {$_.IdentityReference.Value -in $DomainGroupMembership } {
                #Write-Host "Domain group $($_.IdentityReference.Value) -Matched !" -ForegroundColor Yellow
                $ObjectMatches += [PSCustomObject]@{
                    Path = $Path
                    User = $_.IdentityReference.Value
                    ActualFileSystemRight = $_.FileSystemRights
                    RequiredFileSystemRight = $RequiredFileSystemRight
                }

                foreach ($right in $ObjectMatches[-1].RequiredFileSystemRight) {
                    if ($ObjectMatches[-1].ActualFileSystemRight -contains $right) {Write-Host "$($_.IdentityReference.Value) does provide ${right} for path`n`t$Path" -ForegroundColor Green}
                }
            }
            Default {
                #Write-Host "$($_.IdentityReference.Value) Failed :(" -ForegroundColor Red
            }    
        }
    }
    
    process {
        
    }
    
    end {
       $ObjectMatches 
    }
}