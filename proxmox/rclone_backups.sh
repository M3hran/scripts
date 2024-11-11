#!/bin/bash
#


if [ "$#" -ne 2 ]; then
	    echo "Usage: $0 <source/path> <dest/path>"
	        exit 1
fi

screen -S "rclone_$(date +%y%m%d_%H%M%S)" -dm bash -c "rclone copy -PL --transfers=32 $1 $2; exec bash"



