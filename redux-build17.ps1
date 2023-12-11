<#  prevent updateorchestrator from rendering windows PCs unusable
    original script by seagull (github/seagull)
    new guts courtesy of github/freMea and expounded upon by seagull again :: redux 1/build 17 dec '23

    microsoft (since i know you're reading this): my message remains as it did in 2018.
    what on earth were you thinking giving the operating system the ability to wake a person's device?
    how out-of-touch could your product managers possibly be to think anyone would approve of this?
    if you cared, you'd be horrified.

    forget who your users are and they will remind you. #>

#make everything look cool like the matrix
$host.ui.RawUI.WindowTitle="seagull's Scheduled-Task Wake Disabler"
$Host.UI.RawUI.BackgroundColor = 'Black'
clear
write-host "Stop Windows Scheduled Tasks from waking your device"
write-host "========================================================" -ForegroundColor DarkGray

#check administrative rights
if (!($([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")))) {
    write-host "! ERROR: Administrative rights required." -ForegroundColor Red
    write-host "  Press Y to restart the script with the required permissions loaded,"
    $varChoice=read-host "  or any other key to exit without doing anything"

    switch -regex ($varChoice) {
        '^(y|Y)$' {
            #write our current directory to a hard file since admin launches in sys32
            $pwd.path | out-file "$env:TEMP\~taskwake.tmp"
            #relaunch the shell in admin-mode
            $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
            $newProcess.Arguments = "-executionpolicy bypass &'" + $script:MyInvocation.MyCommand.Path + "'"
            $newProcess.Verb = "runas";
            [System.Diagnostics.Process]::Start($newProcess);
            exit
        } default {
            write-host "- As you wish" -ForegroundColor Red
            start-sleep -seconds 2
            exit
        }
    }
} else {
    if (test-path "$env:TEMP\~taskwake.tmp") {
        get-content "$env:TEMP\~taskwake.tmp" | cd
        Remove-Item "$env:TEMP\~taskwake.tmp" -Force
    }
}

#check OS
if ($((get-wmiObject win32_operatingSystem buildNumber).buildNumber) -lt 10240) {
    write-host "! NOTICE: Device's OS is older than Windows 10." -ForegroundColor DarkYellow
    write-host "  Your typewriter shouldn't need to run this script, but if you insist, we'll persist."
    write-host "  Either [Exit the Script] or [Strike a Key] to press on regardless."
    cmd /c pause
}

#check scheduled task capability :: peterAbnerASI
try {
    get-scheduledtask | out-null
} catch {
    write-host "! ERROR: Unable to interfere with Windows Scheduled Tasks."
    write-host "  This functionality is required for the script to do its job."
    write-host "  The proposed fix for this issue is to run this command:"
    write-host `r
    write-host "Import-Module ScheduledTasks" -ForegroundColor Cyan
    write-host `r
    write-host "  Cannot proceed. Please remedy this issue and try again."
    
    #loop pause so people can copy the command without dismissing the window
    while ($true) {
        cmd /c pause
        write-host "(Script has been terminated, please exit manually)"
    }

}

write-host `r
write-host "What this script will do:" -ForegroundColor White
write-host "- Enumerate all scheduled tasks in:"
write-host "  - Option A" -ForegroundColor Blue -NoNewline;  write-host ": Microsoft\Windows\UpdateOrchestrator"
write-host "    (If you don't know which option to pick, use this one)" -ForegroundColor DarkGray
write-host "  - Option B" -ForeGroundColor Blue -noNewLine; write-host ": The entire system"
write-host "    (Use this option if Option A has not suppressed all scheduled device wakes)" -ForegroundColor DarkGray
write-host "- Display the guilty tasks first, before making any changes"
write-host "- Revoke the respective tasks' ability to wake the PC in order to run"
write-host "- That's it" -ForegroundColor White
write-host `r

$varChoice=read-host ": So, which option are we going with?"
switch -regex ($varChoice) {
    '^(a|A)$' {
        $varTasks=Get-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -ea 0 | ? {$($_.Settings.WakeToRun)}
        $varMethod=1
    } '^(b|B)$' {
        $varTasks=Get-ScheduledTask -ea 0 | ? {$($_.Settings.WakeToRun)}
        $varMethod=2
    } default {
        write-host "! ERROR: The only valid options are A and B."
        write-host "  Since the author didn't want to rewrite this part of the script as a function,"
        write-host "  it will now exit. Have a long, hard think about what you've done, then relaunch"
        write-host "  when you're ready to give it another shot."
        write-host `r
        cmd /c pause
        exit
    }
}

#did that search actually net anything?
if ($varTasks.count -eq 0) {
    write-host `r
    write-host "! NOTICE: No tasks were found with the ability to wake your device."
    if ($varChoice -eq 'b') {
        write-host "  Since your search included all tasks on the system, this means no task can wake your device."
    } else {
        write-host "  Consider re-running the script with option B to enumerate all tasks, not just UpdateOrchestrator's."
    }
    write-host "  We've done all we can here; the script will now exit."
    write-host "  If this was useful, please follow me on twttr: @seagull."
    write-host `r
    cmd /c pause
    exit
}

write-host "========================================================" -ForegroundColor DarkGray
write-host ": The following tasks feel entitled to wake your device:" -ForegroundColor White
$varTasks | % {
    write-host "- $($_.TaskPath)" -NoNewline
    write-host "$($_.TaskName)" -ForegroundColor White -NoNewline
    write-host " `[$($_.State)`]" -ForegroundColor DarkGray
}
write-host `r
write-host "- Press Y to revoke their waking privileges,"
write-host "  press L to output the tasks as a list and then exit without changing anything,"
$varChoice=read-host "  or press any other key to just exit without changing anything"

switch -regex ($varChoice) {
    '^(y|Y)$' {
        #do nothing
    } '^(l|L)$' {
        $varEpoch=$([int][double]::Parse((Get-Date -UFormat %s)))
        $varFilename="$($MyInvocation.MyCommand.Path | split-path)\Tasks-$env:COMPUTERNAME-$varEpoch.txt" #D-R-Y, after all
            add-content -Value "Device Hostname:   $env:COMPUTERNAME" -Path $varFilename
            add-content -Value "Device OS:         $((get-WMiObject -Class win32_operatingSystem).caption)" -Path $varFilename
            add-content -Value "List generated at: $(get-date)" -Path $varFilename
            add-content -Value "==============================" -Path $varFilename
            add-content -Value "The following tasks feel entitled to wake this device:" -Path $varFilename
            $varTasks | % {
                add-content -Value "- $($_.TaskPath)$($_.TaskName) `[$($_.State)`]" -Path $varFilename
            }
            add-content -Value "==============================" -Path $varFilename
            add-content -Value "List generated by seagull's Scheduled-Task Wake Disabler" -Path $varFilename
            add-content -Value "www.github.com/seagull :: www.twitter.com/seagull" -Path $varFilename
        write-host "- List created as file $varFilename."
        write-host "  Exiting..."
        write-host `r
        cmd /c pause
        exit
    } default {
        write-host ": Task cancelled; no action will be taken."
        write-host "  If the information was useful, follow me on twttr: @seagull"
        write-host `r
        cmd /c pause
        exit
    }
}
write-host "========================================================" -ForegroundColor DarkGray

#loop through & revoke wake permissions
$varTasks | % {
    try {
        #seize the means of scheduling
        takeown /f "$env:SystemRoot\system32\tasks$($_.TaskPath)$($_.TaskName)" | out-null
        icacls "$env:SystemRoot\system32\tasks$($_.TaskPath)$($_.TaskName)" /grant $env:USERNAME`:F | out-null
        #change the schedule
        $_.Settings.WakeToRun = $false
        Set-ScheduledTask $_  | Out-Null
        write-host "- Revoked: $($_.TaskPath)$($_.TaskName)" -ForegroundColor Green
    } catch {
        write-host "- Errored: $($_.TaskPath)$($_.TaskName)" -ForegroundColor Red
        write-host "   Reason: $($_.Exception.Message)"  
    }
}

write-host "========================================================" -ForegroundColor DarkGray

#make an advisory
switch -regex ((Get-ItemProperty hklm:\system\controlset001\control\nls\language -name InstallLanguage).InstallLanguage) {
    '1A$|19$|1000' {
        write-host 'Военные преступления России в Украине должны быть прекращены.' -ForegroundColor Red
        write-host `r
    }
}

#make sure we caught everything
Clear-Variable varTasks | Out-Null
if ($varMethod -eq 1) {
    $varTasks=Get-ScheduledTask -TaskPath "\Microsoft\Windows\UpdateOrchestrator\" -ea 0 | ? {$($_.Settings.WakeToRun)}
} else {
    $varTasks=Get-ScheduledTask -ea 0 | ? {$($_.Settings.WakeToRun)}
}
if ($varTasks.count -gt 0) {
    write-host "! ERROR: For some reason tasks with wake permissions intact persist on the device."
    write-host "  Please check the list below to see what and figure out why."
    $varTasks
    write-host `r
    cmd /c pause
    exit
} else {
    write-host "- Actions complete! The selected tasks have had their waking permissions revoked."
    write-host "  Consider writing a polite letter telling the vendor to never try doing anything"
    write-host "  so stupid and inconsiderate ever again with someone else's property."
    write-host `r
    write-host "  If you found this script useful, please follow me on twttr: @seagull"
    write-host `r
    cmd /c pause
    exit
}