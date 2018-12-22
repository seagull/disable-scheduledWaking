# Disable Automatic Windows 10 Restarts
Windows 10 was designed with a much more heavily-handed approach to updates than previous iterations. Perhaps as a response to the masses refusing for months to reboot their systems and then blaming the company when they get hit by exploits, MS have made automatic installation of Windows Updates a way of life, with the mandatory reboots that follow being the biggest bone of contention.
I believe power users should have sole authority of when their devices reboot, and I have [some background on the topic](https://superuser.com/questions/973009/conclusively-stop-wake-timers-from-waking-windows-10-desktop), so it seemed like time I put my scripting skills to use and created a simple way to automate the process of disabling automatic restarts for good.

## How it works
The script is fairly simple. The mechanism by which reboots are achieved is a Scheduled Task located in System32 in XML format. Modifying this file causes Windows to reject it out of well-placed concerns for security; while this is a quick and easy way to accomplish the task, it's messy and can't be reverted.  
Instead of modifying the file as the logged-in user, the script instead utilises the [PSExec](https://docs.microsoft.com/en-us/sysinternals/downloads/psexec) binary from Microsoft SysInternals to carry through a series of modifications as the `NT AUTHORITY\SYSTEM` user, which overrides Windows' security rejection. This way, all changes made can easily be reverted in the case of unforeseen consequences.

## What it does
- When disabling:
    - Uses `Schtasks` via `PSExec` to disable the task and set its command to `CMD /C REM`, which does nothing, so that the task would do nothing even if run by force
    - Uses `Set-ACL` to block read/write access to all users of the device, so that nothing can make valid use of it
- When re-enabling:
    - Uses `Schtasks` via `PSExec` to re-enable the task and replace its settings to Windows' defaults
    - Uses `Set-ACL` to return all user read/write permissions to the file so that the system can make use of it

## Acknowledgements
The script has been tested and worked fine on an English Windows 10 VM. It also worked fine on a German VM I had for testing purposes, although it threw some errors because it wants access to be qualified to `Administratoren` instead of the English `Administrators`. I don't consider this a big enough issue to worry about.

## Guarantee
I attach no guarantee of functionality to this script. Use it at your own risk.  
If you bollocks up your system from using this I won't be held responsible.

## Feedback
Did this script work strangely on your system or cause problems? [File an issue.](https://github.com/seagull/disable-automaticrestarts/issues)  
Did everything work perfectly? [Follow me on Twttr.](https://www.twitter.com/seagull) (I don't post and won't reply to messages.)
