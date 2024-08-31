# TaskSchedulerAutomation #

Create Scheduled tasks using a gMSA (service account) within an Active Directory environment, without having to trouble shoot file permissions (or atleast having bespoke tooling to do so). 

### What is this repository for? ###

* Create a Service Account, run .\scripts\CreateGMSA.ps1 on your domain controller (read the file and edit parameters).
* Use functions in .\bin
	* Get-TSAFileAccess: Compare granular file permissions
	* Set-TSAFileAccess: Set granular file permissions
	* New-TSADailyTask: Create a scheduled task that executes daily.
* Check functionality using .\tests
	* .\tests follow the conventions of Pester (without actually using pester). I found this an easy alternative for smaller powershell libraries.
	* .\tests\New-TSADailyTask.Tests.ps1 Creates a scheuled task using a service account, and executes msg.exe with a count down for the current user. This exemplifies the modules utility

### How do I get set up? ###

* Clone this repo
* Put it in your $PSModulePath, or impot with ``` Import-Module -FullyQualifiedName .\TaskSchedulerAutomation.ps1 ```
* Create a Service account with .\scripts\CreateGMSA.ps1
* Make sure you have set the GPO to allow your service account to have the logon as service right for your current machine
	* pending screenshot
	* ![Demo of the Project](https://github.com/raref-public/TaskSchedulerAutomation/repo_pics/GPO_SETTINGS.png)

* Test your domain, service account with the .\tests\New-TSADailyTask.Tests.ps1

### Contribution guidelines ###

* fork the repo, write tests merge if you want to. Or however this github thing works lol.

### Who do I talk to? ###

* Grigori Rasputin
	* ``` SingSong('There lived a certian man in Russia long ago ...') ```