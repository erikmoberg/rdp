# rdp
Utils for Windows Remote Desktop

## rdp-multimon.ps1
This script will discover the current monitors, find the latest *.rpd file in the current user's download folder, 
and (by default) open the remote session with the 2 leftmost available monitors. The script assumes all monitors
are on the same level (configurations with monitors placed above top of each other are not supported).
