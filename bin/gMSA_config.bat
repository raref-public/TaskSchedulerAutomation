@echo off

set TASKNAME=%1
set ACCOUNT=%2
set DOMAIN=%3
set FOLDER=%4

echo Changin scheduled task "%TASKNAME%" to run under account: "%ACCOUNT%"

echo schtasks /change /TN \%FOLDER%\%TASKNAME% /RU %DOMAIN%\%ACCOUNT% /RP
schtasks /change /TN \%FOLDER%\%TASKNAME% /RU %DOMAIN%\%ACCOUNT% /RP