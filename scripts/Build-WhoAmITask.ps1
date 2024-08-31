<#
.DESCRIPTION
this is a test file to make sure that the appropriate service accounts can run on the respective server
#>

# stop on error
$ErrorActionPreference = 'Stop'

# load relative functions
. "${PSScriptRoot}\Initialize-ServiceAccountRWE.ps1"

# create and compile a quick c# program that prints current username to file
$SheSharpCompilerPath = Get-ChildItem -Path "$($env:SystemRoot)\Microsoft.NET\Framework\*" -Recurse -Include "*csc.exe" | Select-Object -First 1 -ExpandProperty FullName
if (-Not (Test-Path -Path $SheSharpCompilerPath)) {Write-Error -Category InvalidData -Message "Compiler not found"}

# file to create
$SheSharp = @"
using System;
using System.IO;

class Program
{
    static void Main()
    {
        // Get the username
        string userName = Environment.UserName;

        // Get the path to the public desktop
        string publicDesktopPath = Environment.GetFolderPath(Environment.SpecialFolder.CommonDesktopDirectory);

        // Create the file path
        string filePath = Path.Combine(publicDesktopPath, "username.txt");

        // Write the username to the file
        File.WriteAllText(filePath, userName);
    }
}
"@

# location for testfiles
$UserProfile = $env:USERPROFILE
$PublicDesktop = [Environment]::GetFolderPath("CommonDesktopDirectory")
Write-Warning "This test adds service account access to your home directory !!! remove this access after testing. FileExplorer > properties > security > ServiceAccount$ > remove etc"

# set permissions

Initialize-ServiceAccountRWE -DirectoryPaths @($PublicDesktop) `
    -Domain "${DOMAIN}" `
    -Account '${SERVICE_ACCOUNT}$' `
    -Attributes "ReadAndExecute, Write"

$SheSharpPath = "${PublicDesktop}\SheSharp.cs"
$SheSharpOut = $SheSharpPath -replace '.cs', '.exe'
New-Item -Path $SheSharpPath -Value $SheSharp -Force

# compile
Start-Process $SheSharpCompilerPath -ArgumentList "-out:${SheSharpOut}", "${SheSharpPath}"




function Build-WhoAmITask {
    [CmdletBinding()]
    param (
        $SchtaskFolder="${FOLDER_NAME}",
        $SchtaskName="WhoAmI",
        $FQSchtaskName="\${SchtaskFolder}\WhoAmI",
        $Executable,
        $ServiceAccount='${SERVICE_ACCOUNT}'
    )
    
    begin {
        $ErrorActionPreference = 'Stop'
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
        $actions = (New-ScheduledTaskAction -Execute "${Executable} ")
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddSeconds(60)
        $principal = New-ScheduledTaskPrincipal -UserId "${DOMAIN}\$($env:USERNAME)" -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun #-Compatibility 
        $task = New-ScheduledTask -Action $actions -Principal $principal -Trigger $trigger -Settings $settings

        # register task 
        Register-ScheduledTask -TaskName "${SchtaskName}" -TaskPath "\${SchtaskFolder}" -InputObject $task 
    }
    
    process {
    }
    
    end {
        cmd.exe /C "${PSScriptRoot}.\..\bin\gMSA_config.bat ${SchtaskName} ${ServiceAccount}"
    }
}

Build-WhoAmITask -Executable $SheSharpOut

Invoke-Item -Path $PublicDesktop
taskschd.msc