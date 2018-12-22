# Disable-AutomaticRestarts.ps1 by seagull
$varScriptTitle="Disable Windows 10 Automatic Reboots"
$host.ui.RawUI.WindowTitle = $varScriptTitle + " (build 34)"
# Shame on you, Microsoft. I shouldn't have to do this.
# If I wanted my computer to be governed by reckless, 
# inconsiderate fuckwads I'd have bought a Macintosh.
# ====================================================

# - - - - - - - - - - - - - - - boilerplate - - - - - - - - - - - - - - -

$Host.UI.RawUI.BackgroundColor = 'Black'
clear
$varScriptDir = split-path -parent $MyInvocation.MyCommand.Definition
$varAdmin=([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"))
[int]$varCorrectPoints=0
Function fcnEpochTime {[int][double]::Parse((Get-Date -UFormat %s))}
$varEpoch=$(fcnEpochTime)

# - - - - - - - - - - - - - - - -functions- - - - - - - - - - - - - - - -

function optionScreen {
    $script:varCheckAgain=$true
    write-host "`r"
    write-host "                        Press your button to continue: " -ForegroundColor Blue -NoNewline
    $choiceInput = Read-Host
    write-host "`r"
    switch -Regex ($choiceInput) {
        '^Q$|^q$' {
            $script:varModeSelection="disableTask"
        }

        '^Z$|^z$' {
            $script:varModeSelection="imposeDefaults"
        }
    }
}

function imposeDefaults {

    #get boge
    write-host "Option selected: " -NoNewline; write-host "Re-enable `'Reboot`' Task." -ForegroundColor Green
    write-host `r

    write-host "`- Please note that this operation will return read/write access to the `'Reboot`' task"
    write-host "  for all users (including System) in order for the script to work with it."
    write-host "  Close the script NOW to quit without making any changes or press any key to proceed."
    cmd /c pause | out-null
    write-host `r

    #regain control over the file
    $acl = Get-Acl "C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot"
    $acl.Access | %{$acl.RemoveAccessRule($_)} 2>&1>$null

    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("$env:ComputerName\$env:UserName","FullControl","Allow")
    $acl.SetAccessRule($AccessRule)
    $acl | Set-Acl "C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot"

    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM","FullControl","Allow")
    $acl.SetAccessRule($AccessRule)
    $acl | Set-Acl "C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot"

    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl","Allow")
    $acl.SetAccessRule($AccessRule)
    $acl | Set-Acl "C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot"

    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("LocalService","FullControl","Allow")
    $acl.SetAccessRule($AccessRule)
    $acl | Set-Acl "C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot"

    #get xml data
    [xml]$xmlReboot= get-content "C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot" 2>$null

    #check we got something
    if (!$xmlReboot.Task.Settings.Enabled) {
        write-host "`- Couldn't find any trace of the task on the system. The script will re-generate one." -ForegroundColor Yellow
        $varCreateNew=$true
    }

    write-host "- Read/write permissions have been returned to the `'Reboot`' task."

    if ($varCreateNew) {
        write-host "- Producing new task..." -ForegroundColor Green
    } else {
        write-host "- Reverting task settings..." -ForegroundColor Green
    }
    start-sleep -seconds 3

    set-content "$varScriptDir\Operation-$varEpoch.ps1" -value '#Disable Windows 10 Automatic Reboots - A tool by seagull'

    if ($varCreateNew) {
        add-content "$varScriptDir\Operation-$varEpoch.ps1" -value 'cmd /c schtasks /create /sc once /tn "Microsoft\Windows\UpdateOrchestrator\Reboot" /tr "%systemroot%\system32\MusNotification.exe RebootDialog" /st 00:00 /RU SYSTEM'
    } else {
        add-content "$varScriptDir\Operation-$varEpoch.ps1" -value 'cmd /c schtasks /change /tn "Microsoft\Windows\UpdateOrchestrator\Reboot" /ENABLE /tr "%systemroot%\system32\MusNotification.exe RebootDialog" /st 00:00 /RU SYSTEM'
    }
}

function disableTask {
    #get boge
    write-host "Option selected: " -NoNewline; write-host "De-activate `'Reboot`' Task." -ForegroundColor Green
    write-host `r
    write-host "Here's what we're going to do:"
    write-host "`- Disable the existing `'Reboot`' Scheduled Task in the Task Scheduler"
    write-host "`- Edit it so even if it were run by force it would do nothing"
    write-host "`- Configure things so no user - not even you - can write to it again"
    write-host "`- This will completely stop your machine from automatically rebooting" -ForegroundColor Red
    write-host `r
    write-host "Press any key to proceed." -ForegroundColor Cyan
    cmd /c pause | out-null

    #get xml data
    [xml]$xmlReboot= get-content "C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot" 2>$null

    #check we got something
    if (!(test-path variable:xmlReboot)) {
        write-host "`- Couldn't find any trace of the task on the system. Was it deleted?" -ForegroundColor Yellow
        write-host "`--  The script will generate a toothless one."
        set-content "$varScriptDir\Operation-$varEpoch.ps1" -value "`#Disable Windows 10 Automatic Reboots - A tool by seagull 
psexec.exe -accepteula -i -s cmd /c schtasks /create /sc once /tn `"Microsoft\Windows\UpdateOrchestrator\Reboot`" /tr `"CMD /C REM`" /st 00:00 /RU SYSTEM"
    } else {
        set-content "$varScriptDir\Operation-$varEpoch.ps1" -value "`#Disable Windows 10 Automatic Reboots - A tool by seagull"
    }

    add-content "$varScriptDir\Operation-$varEpoch.ps1" -value "cmd /c schtasks /change /tn `"Microsoft\Windows\UpdateOrchestrator\Reboot`" /DISABLE /tr `"CMD /C REM`"

`$acl = Get-Acl `"C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot`"
`$acl.Access | %{`$acl.RemoveAccessRule(`$_)} 2>&1>`$null

`$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(`"Administrators`",`"FullControl`",`"Deny`")
`$acl.SetAccessRule(`$AccessRule)
`$acl | Set-Acl `"C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot`"

`$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(`"SYSTEM`",`"FullControl`",`"Deny`")
`$acl.SetAccessRule(`$AccessRule)
`$acl | Set-Acl `"C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot`"

`$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(`"LocalService`",`"FullControl`",`"Deny`")
`$acl.SetAccessRule(`$AccessRule)
`$acl | Set-Acl `"C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot`"

`$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(`"$env:ComputerName\$env:UserName`",`"FullControl`",`"Deny`")
`$acl.SetAccessRule(`$AccessRule)
`$acl | Set-Acl `"C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator\Reboot`""

}

# - - - - - - - - - - - - - - - - start - - - - - - - - - - - - - - - - -

write-host "       $varScriptTitle" -NoNewline
write-host " - a PowerShell tool by seagull" -ForegroundColor DarkGray
write-host "================================================================================="
write-host `r

$global:varKernel=(([System.Diagnostics.FileVersionInfo]::GetVersionInfo("C:\Windows\system32\kernel32.dll").FileVersion).split(".")[2])
if ($varKernel -le 10240) {
    write-host "This script requires Windows 10 and is not required on anything lower."
    write-host "It will now exit without making any modifications to your system."
    cmd /c pause
    exit
}

#decant toys from bassinet if we lack admin access
if (!$varAdmin) {
    write-host "`- ERROR: This script needs to be run as an Administrator to do what it needs to."
    write-host "  Press ENTER to re-start script as an Admin (you might receive a UAC popup):"
    cmd /c pause | out-null

    # switch over to admin mode
    #write our current directory to a hard file since admin launches in sys32
    $pwd.path | out-file "$env:TEMP\~DisableReboot.tmp"
    #relaunch the shell in admin mode
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
    $newProcess.Arguments = "-executionpolicy bypass &'" + $script:MyInvocation.MyCommand.Path + "'"
    $newProcess.Verb = "runas";
    [System.Diagnostics.Process]::Start($newProcess);
    exit
} else {
    if (test-path "$env:TEMP\~DisableReboot.tmp") {
        get-content "$env:TEMP\~DisableReboot.tmp" | cd
        Remove-Item "$env:TEMP\~DisableReboot.tmp"
        $varScriptDir = $pwd.path
    }
}

#introduce to user
write-host "      This script can either alter and disable the `'Reboot`' Scheduled task,"
write-host "           rendering it toothless, or reverse changes made previously."
write-host `r
write-host "=================================================================================" -ForegroundColor DarkGray
write-host "      PRESS [" -nonewline; write-host "Q" -foregroundcolor Red -nonewline; write-host "] TO DE-ACTIVATE THE      " -NoNewline
write-host "|" -NoNewline -foregroundcolor DarkGray; write-host "       PRESS [" -nonewline; write-host "Z" -foregroundcolor Red -nonewline; write-host "] TO RE-ENABLE THE       "
write-host "        `'Reboot`' SCHEDULED TASK.        " -NoNewline; write-host "|" -ForegroundColor DarkGray -NoNewline; write-host "        `'Reboot`' SCHEDULED TASK.        "
write-host "=================================================================================" -ForegroundColor DarkGray
write-host `r

while (!$script:varModeSelection) {
    if ($script:varCheckAgain) {
        write-host "                        Wrong button! Pick `'Q`' or `'Z`'!" -ForegroundColor Red
    }
    optionScreen
}

# - - - - - - - - - - - - - - - - psexec - - - - - - - - - - - - - - - -

#check PATH for PSExec.exe
write-host "`- Checking for PSExec installation..." -ForegroundColor Cyan
#do it with a foreach instead of a simple "check this then download" because the PATH can have multiple values
foreach ($iteration in $env:path.split(";")) {
    if (test-path "$iteration\psexec.exe") {
        $script:varPSExecPath="$iteration\psexec.exe"
        write-host "`-- PSExec binary found at $iteration\psexec.exe."
        break
    }
}

if (!(test-path variable:script:varPSExecPath)) {
    #download pstools
    write-host "`-- PSExec not present; downloading it... " -NoNewline
    (New-Object net.webclient).DownloadFile("https://download.sysinternals.com/files/PSTools.zip","$varScriptDir\PSTools.zip")
    #permit a moment for defender to scan it
    start-sleep -seconds 3

    #did it actually download tho
    if (!(test-path PSTools.zip)) {
        Write-Host "Failed" -ForegroundColor Red
        write-host "   The script requires, but could not download, PSExec."
        write-host "   Exiting: Please check your internet connection and retry."
        cmd /c pause
        exit
    } else {
        write-host "Succeeded!" -ForegroundColor Cyan
    }

    #extract it. this is PS5 so we can use extract-archive thanque fucque
    Expand-Archive PSTools.zip "$varScriptDir\PSTools"
    start-sleep -seconds 3
    Copy-Item "$varScriptDir\PSTools\PsExec.exe" "C:\Windows\System32"
    Remove-Item "$varScriptDir\PSTools" -Force -Recurse
    remove-item "$varScriptDir\PSTools.zip" -Force
    write-host "`-- PSExec binary copied to System32."
}

write-host `r
& $script:varModeSelection

write-host `r
write-host "`- Contents of file to be processed through PSExec:"
write-host "=================================================================================" -ForegroundColor DarkGray
get-content "$varScriptDir\Operation-$varEpoch.ps1"
write-host "=================================================================================" -ForegroundColor DarkGray
write-host `r
write-host "Press any key to commit changes." -ForegroundColor Cyan
cmd /c pause | out-null
write-host "`- Running file..."
psexec -accepteula -s powershell -executionPolicy unrestricted -file "$varScriptDir\Operation-$varEpoch.ps1"
remove-item "$varScriptDir\Operation-$varEpoch.ps1"
write-host `r
write-host "`- Process completed!" -ForegroundColor Green
write-host "`-- Press [" -NoNewline; write-host "A" -NoNewline -ForegroundColor Red; write-host "] to load the Task Scheduler to check or [" -NoNewline
write-host "ENTER" -ForegroundColor Red -NoNewline; write-host "] to exit the script: " -NoNewline

#choice statement
$choiceInput = read-host
switch -Regex ($choiceInput) {
    default {
        write-host `r
        write-host "If this was useful, follow me on Twttr" -NoNewline
        write-host " @seagull" -ForegroundColor Blue
        start-sleep -seconds 5
        exit
    }

    'A|a|Y|y' {
        write-host `r
        write-host "If this was useful, follow me on Twttr" -NoNewline
        write-host " @seagull" -ForegroundColor Blue
        start-sleep -Seconds 2
        cmd /c start "" $env:windir\system32\mmc.exe /s taskschd.msc
        start-sleep -seconds 5
        exit
    }
}