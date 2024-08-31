<#
.DESCRIPTION
used to create daily tasks
#>
function New-TSADailyTask {
    [CmdletBinding()]
    param (
        $SchtaskFolder,
        $SchtaskName,
        $Executable,
        $SchtaskArgumentString,
        $ServiceAccount,
        $At,
        $Domain
    )
    
    begin {
        $IsElevated = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        if (-Not $IsElevated) {Write-Error -Category PermissionDenied -Message "Must run in elevated context"}

        # make user root folders available
        $scheduledObject = New-Object -ComObject schedule.service
        $scheduledObject.connect()
        $rootFolder = $scheduledObject.GetFolder("\")
        try {
            $scheduledObject.GetFolder("\${SchtaskFolder}")
        }
        catch [System.IO.FileNotFoundException] {
            $rootFolder.CreateFolder("${SchtaskFolder}")
        }
        
        # build PostProduction task
        $actions = (New-ScheduledTaskAction -Execute "${Executable}" -WorkingDirectory (Split-Path -Path "${Executable}") -Argument $SchtaskArgumentString)
        $trigger = New-ScheduledTaskTrigger -Daily -At $At
        $principal = New-ScheduledTaskPrincipal -UserId "${Domain}\$($env:USERNAME)" -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun #-Compatibility 
        $task = New-ScheduledTask -Action $actions -Principal $principal -Trigger $trigger -Settings $settings

        # register task 
        Register-ScheduledTask -TaskName "${SchtaskName}" -TaskPath "\${SchtaskFolder}" -InputObject $task -Verbose
    }
    
    process {
        
    }
    
    end {
        cmd.exe /C "${PSScriptRoot}.\gMSA_config.bat ${SchtaskName} ${ServiceAccount}"
        foreach ($i in (29 .. 1)) {
            Write-Output "Scheduled task executing in ${i}"
            Start-Sleep 1
        }
    }
}