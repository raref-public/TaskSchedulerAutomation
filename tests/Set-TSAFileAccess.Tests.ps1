<#
.DESCRIPTION
reload module and test function based of naming convention:
 - $ModuleFunction is name of the function
 - functions script file is $ModuleFunction.ps1
 - test file is the same, but $ModuleFunction.Tests.ps1

# MUST BE DEFINED FOR FUNCTION
ex.
$ModuleFunctionArgs = @{
    arg1 = 'Param1'
}

#>
# DEFINE YOUR DOMAIN  AND SERVICE ACCOUNT !!!
$DOMAIN=((Get-WmiObject Win32_ComputerSystem).Domain).split('.')[0] -replace "`n" # so if your domain is consto.local, just put consto
$SERVICE_ACCOUNT="PacketP_gMSA$" # service accounts sAMAccountName end with a $, just like computer objects in AD

# test if module present then reload module import
$ModuleName = 'TaskSchedulerAutomation' 
$ModuleFQPath = "${PSScriptRoot}\..\${ModuleName}.psm1"
$ModuleFunction = (Split-Path "$PSCommandPath" -Leaf) -replace '.Tests.ps1'

# MUST BE DEFINED FOR FUNCTION
# test 1
$ModuleFunctionArgs_1 = @{
    DirectoryPaths = @(
        "${PSScriptRoot}\..\acl_reference\test_acl_dir"
        "${PSScriptRoot}\..\acl_reference\test_acl_dir_pam"
    )
    Domain = "${DOMAIN}"
    Account = "${SERVICE_ACCOUNT}"
    Attributes = "ReadAndExecute, Write"
}

function CallAndPrint ($ModuleFunction, $ModuleFunctionArgs) {
    # formatting
    $Invocation = "${ModuleFunction} @ModuleFunctionArgs"

    # print to user
    Write-Host "CALLING:`n`t${Invocation}`nOUTPUT:" -ForegroundColor Yellow

    # call function
    Invoke-Expression "$Invocation"
}

# load module
$module = Get-Module -Name $ModuleName  -ErrorAction SilentlyContinue

if ($module) {
    Remove-Module $module
}

# implicit presumption that module importation has not broken
Import-Module -FullyQualifiedName  $ModuleFQPath

# test function 1
CallAndPrint -ModuleFunction $ModuleFunction -ModuleFunctionArgs $ModuleFunctionArgs_1


# done 23/07/2024 ~ 03:08 PM