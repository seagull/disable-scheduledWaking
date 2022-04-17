# seagull's Scheduled-Task Wake Disabler
Windows 10 and onward were designed with a much more heavily-handed approach to updates than previous iterations. Perhaps as a response to the masses refusing for months to reboot their systems and then blaming the company when they get hit by exploits, MS have removed a lot of options from Windows Updates' user experience.
This process of dragging users kicking and screaming into responsibility has created an unfortunate by-product in a series of scheduled tasks that will wake a device up in order to install updates if it knows any are due.

I believe power users should have sole authority of when their devices sleep and wake, and I have [some background on the topic](https://superuser.com/questions/973009/conclusively-stop-wake-timers-from-waking-windows-10-desktop), so it seemed like time I put my scripting skills to use and created a simple way to automate the process of disabling automatic wakes-up for good.

## How it works
This script has been re-written entirely from its December 2018 iteration. Thanks to some streamlined code courtesy of @freMea, I have done away with all of the arsing around in PSExec and editing scheduled tasks directly by their XML. Instead, the script simply enumerates all scheduled tasks on the system – either the ones specific to Microsoft Update or broadly across the entire system – with the ability to wake the device up at their leisure, and puts the control of that permission back in the rightful hands of the user. In order to accomplish this the tasks have their ownership seized to be made the property of the user running the script.

## What it does
It uses `get-scheduledTask` to enumerate all enabled tasks on the device with the `WakeToRun` privilege, using `icacls` and `takeown` to make them the property of the person running the script. This is not dissimilar to what the older script did but the process now incurs significantly less of a headache.
If the user chooses so, a list containing the tasks can be produced without _doing_ anything to them; alternatively, they are iterated through and their privileges to wake the system are revoked.

## Acknowledgements
This script uses some logic from @freMea who left a very helpful comment in the issues of the original script.
It has been tested on Windows 10 and Windows 11, English and German.
You really shouldn't need to run it on anything earlier than Windows 10, but it will allow you to if you insist.

## Guarantee
I attach no guarantee of functionality to this script. Use it at your own risk.  
If you bollocks up your system from using this I won't be held responsible.

## Feedback
Did this script work strangely on your system or cause problems? [File an issue.](https://github.com/seagull/disable-automaticrestarts/issues)  
Did everything work perfectly? [Follow me on Twttr.](https://www.twitter.com/seagull) (I don't post and won't reply to messages.)
