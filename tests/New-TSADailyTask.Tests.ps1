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
# TBE find the exact rights to use msg.exe, at the moment added user to local admin
#Add-LocalGroupMember -Group 'Administrators' -Member "${DOMAIN}\${SERVICE_ACCOUNT}"

# test if module present then reload module import
$ModuleName = 'TaskSchedulerAutomation' 
$ModuleFQPath = "${PSScriptRoot}\..\${ModuleName}.psm1"
$ModuleFunction = (Split-Path "$PSCommandPath" -Leaf) -replace '.Tests.ps1'

# MUST BE DEFINED FOR FUNCTION
# test 1
$ModuleFunctionArgs_1 = @{
    SchtaskFolder = "${DOMAIN}"
    SchtaskName = "TEST"
    Executable = 'C:\Windows\System32\msg.exe'
    AddExecutePermissions = $true
    SchtaskArgumentString = "/SERVER:localhost $env:USERNAME  Congratulations you have configured and built a scheduled task!"
    ServiceAccount = "${SERVICE_ACCOUNT}"
    At = (Get-Date).AddSeconds(10)
    Domain = "${DOMAIN}"
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
