#!/bin/bash

# Usage: clamscan.sh <clamscan.conf>
# Example: /root/scripts/clamscan.sh /root/clamscan.conf


# Error if no config file passed to clamscan.sh
if [[ -z "$1" ]]; then
    echo "Error: please specify a configuration file, e.g. $0 /root/clamscan.conf"
    exit 1
fi

# Error if bad config file.
# Also sets source to config file. This line is required for script to work.
if ! source "$1"; then
    echo "Error: can't load configuration file $1"
    exit 1
fi

# Set current epoch time - rollback time for safety
current_time=$(( $(date +'%s') - $rollback ))

virus=no

# Temporary list_file
listfile_tmp=$(mktemp -t listfile.XXXXXXXXXX)

# Remove listfile_tmp on exit
trap 'rm -f "$listfile_tmp"' EXIT

# Function to exit if clamscan returns error
clamexit() {
	if [ $? -ne 0 ]; then
		virus=yes
	fi
}

# Update freshclam definitions
/usr/bin/freshclam --quiet
if [ $? -ne 0 ]; then
	echo "Updating virus definitions with freshclam failed"
	exit 1
fi

# Clear and date the clam_log
echo "All scans in this log started $(date)" > "$clam_log"

# Check for EPOCHTIME=0
if [[ "$EPOCHTIME" -eq 0 ]]; then
	# Run full scan of date_scan_array
	for i in "${date_scan_array[@]}"
	do
		/usr/bin/clamscan -i -r "$i" >> "$clam_log"
		clamexit
		printf "\n" >> "$clam_log" 
		sed -i "s|SCAN SUMMARY -|SCAN SUMMARY ${i} -|" "$clam_log"
	done
else
	# Check array for files younger than EPOCHTIME
	for i in "${date_scan_array[@]}"
	do
		# List files that are younger than EPOCHTIME
		find "$i" -type f -newermt "@${EPOCHTIME}" -print >> "$listfile_tmp"
	done
	# Scan files in listfile_tmp
	/usr/bin/clamscan -i -f "$listfile_tmp" >> "$clam_log"
	clamexit
	printf "\n" >> "$clam_log" 
	sed -i "s|SCAN SUMMARY -|SCAN SUMMARY ${date_scan_array[*]} -|" "$clam_log"
fi

for i in "${full_scan_array[@]}"
do
	/usr/bin/clamscan -i -r "$i" >> "$clam_log"
	clamexit
	printf "\n" >> "$clam_log" 
	sed -i "s|SCAN SUMMARY -|SCAN SUMMARY ${i} -|" "$clam_log"
done

# Change EPOCHTIME in clamscan.conf to current_time if no virus or errors
if [ $virus == no ]; then
	sed -i "/^EPOCHTIME=/c\EPOCHTIME=${current_time}" "$1"
else
	cat "$clam_log" | mail -s "ClamAV Error or Virus Detected" "$email"
fi

exit
