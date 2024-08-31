<# 
.DESCRIPTION
This is the main 'script module' which is run at import

#>

# notify user of importation
Write-Host "Loading Module $PSScriptRoot" -ForegroundColor Green

# LOAD IN FUNCTIONS / CMDLETS

# loading any *.ps1 from $ImportDirectories array.
$ImportDirectories = @()
$ImportDirectories += (Get-ChildItem -Path "$PSScriptRoot\bin\*" -Include "*.ps1" -Recurse -File)

$ImportDirectories `
    | Where-Object -Property Extension -EQ '.ps1' `
    | ForEach-Object {

        # notify user of import function path
        Write-Host "Importing $($_.FullName)" -ForegroundColor DarkGreen

        # notify user of test file
        $TestFile = "$PSScriptRoot\tests\$($_.Name -replace '.ps1', '.Tests.ps1')"
        $TestFilePresent = Test-Path $TestFile

        if (-Not ($TestFilePresent)) {
            Write-Warning "$($_.Name) has no $($_.Name -replace '.ps1', '.Tests.ps1') file"
        }

        # source function
        . $_.FullName
        
        # check for aliases, otherwise export function as is.
        $alias = Get-Alias -Definition $_.BaseName -ErrorAction SilentlyContinue
        if ($alias) {
            Export-ModuleMember $_.BaseName -Alias $alias
        }
        else {
            Export-ModuleMember $_.BaseName 
        }
    }