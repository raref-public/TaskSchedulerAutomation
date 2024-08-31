<#
.DESCRIPTION
read:
- https://learn.microsoft.com/en-us/dotnet/api/system.security.accesscontrol.filesystemrights?view=net-8.0

specify domain without subomain  - 'consto', instead of 'consto.local'
#>
function Set-TSAFileAccess {
    [CmdletBinding()]
    param (
        [string[]]$DirectoryPaths,
        $Domain,
        $Account,
        $Attributes
    )
    
    begin {
        foreach ($DirectoryPath in $DirectoryPaths) {
            # create filesystem object, 2nd arugument sets permissions - using comma seperated string
            $FileSystemObj_AclRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                "${Domain}\${Account}",
                "${Attributes}",
                "ContainerInherit, ObjectInherit",
                "None",
                "Allow"
            )

            # get current acl of the directory
            $Acl = Get-Acl -Path $DirectoryPath

            # add access rule to current acl
            $Acl.AddAccessRule($FileSystemObj_AclRule)

            # set the acl back on the directory
            $Acl | Set-Acl -Path $DirectoryPath
        }
    }
    
    process {
        
    }
    
    end {
        foreach ($DirectoryPath in $DirectoryPaths) {
            (Get-Acl -Path $DirectoryPath).Access `
                | Where-Object -Property IdentityReference -EQ "${Domain}\${Account}"
        }
        
    }
}
