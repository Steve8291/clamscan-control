# clamscan-control
Script and config file that use clamav to scan based on modification dates

This script was written for Ubuntu and is unlikely to work on other non-Debian distros like BSD, etc.
Realize that this is not as complete of protection as scanning your entire system after every virus def update.
If you have a file in the date_scan_array that is infected with a currently unknown virus, this file will not be rescanned when that virus definition happens to be added to the clamav definitions. Files in the full_scan_array will be scanned every time. Use at your own risk.
I created this because a full clamav scan takes upwards of 6 hours on my system.
It will allow you to select directories that you want to run full scans on as well as ones in which you wish to only scan files that were modified since the last scan.
Additionally there is an option to set rollback time. Default is set to rollback=300 (5 min)
Rollback will allow you to rescan older files for a little redundancy if you like. For instance, you could set it to scan all files that are 24 hours older than last scan: rollback=86400


## DIRECTIONS
Install clamav clamav-base clamav-freshclam
  apt install clamav
Do not insatll the daemons: clamdscan clamav-daemon
Disable the freshclam daemon from running at startup (optional).
I don't see any sense in updating virus defs every min when you don't scan that often.
```
/etc/init.d/clamav-freshclam stop
update-rc.d -f clamav-freshclam disable
```
Edit freshclam.conf and comment out NotifyClamd and Checks:
```
nano /etc/clamav/freshclam.conf
	# NotifyClamd /etc/clamav/clamd.conf
    	# Checks 24
```
You don't need to notify clamd since you didn't install it.
Run freshclam to see if it is working
```
freshclam
```
Download both the clamscan.sh and clamscan.conf files from this git
You can locate these anywhere you like but should probably set permissions to 700 for both.
The config file is well commented. Add the directories you wish to scan to it.
Run your first scan. NOTE: this is probably going to take hours to finish.
```
/path/to/clamscan.sh /path/to/clamscan.conf &
```
The "&" runs the command in the background.
You can check if it has finished with the jobs or top command.
After the first run you should see an updated value for the variable EPOCHTIME= in clamscan.conf
You can also check your clamscan.log file to see that the scans were completed.
NOTE: Don't use the time it took for the first scan to complete for your rollback time.
Check to see how long scans are taking after you have run a few cron jobs with the script.
Add the following line to cron with:
```
crontab -e
    # Update freshclam virus defs & scan sensitive areas @2:54am
    54 2 * * * /path/to/clamscan.sh /path/to/clamscan.conf
```
