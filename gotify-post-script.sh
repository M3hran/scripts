##!/bin/bash

# #### Example Post Script
# #### $1=EXIT_CODE (After running backup routine)
# #### $2=DBXX_TYPE (Type of Backup)
# #### $3=DBXX_HOST (Backup Host)
# #### #4=DBXX_NAME (Name of Database backed up
# #### $5=BACKUP START TIME (Seconds since Epoch)
# #### $6=BACKUP FINISH TIME (Seconds since Epoch)
# #### $7=BACKUP TOTAL TIME (Seconds between Start and Finish)
# #### $8=BACKUP FILENAME (Filename)
# #### $9=BACKUP FILESIZE
# #### $10=HASH (If CHECKSUM enabled)
# #### $11=MOVE_EXIT_CODE
#
###
# send gotify push notification post run
##

URL="https://gotify.parallaxsystem.com/message?token=AuSuv0xlXYX7xti"
PRIORITY="5"
declare TITLE MESSAGE

send_push()
{

    curl -sSL --output /dev/null -w "%{http_code}\n" -X POST \
        "$URL" \
        -F "title=$TITLE" -F "message=$MESSAGE" -F "priority=$PRIORITY"
}




if [ $1 -eq 0 ]; then
	TITLE="DB-BACKUP: SUCCESSFUL!"
	MESSAGE="__$4__ backup complete in $7 seconds. Size: $9 Filename: $8"
	send_push
else
        TITLE="DB-BACKUP: FAILED!"
        MESSAGE="__$4__ backup failed.: $2 $3 "
        send_push
fi


