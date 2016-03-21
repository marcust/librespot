#
# Regular cron jobs for the librespot package
#
0 4	* * *	root	[ -x /usr/bin/librespot_maintenance ] && /usr/bin/librespot_maintenance
