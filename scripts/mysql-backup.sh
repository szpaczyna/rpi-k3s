#!/bin/bash

## Variables
HOST=$(hostname -s)
DELETE_BACKUPS_OLDER_THAN_DAYS=30
syslogtag=MySQL-Backup
DEST=/backup/
DBS="$(mysql -u root -Bse 'show databases' | grep -Ev '^Database$|hold$' | grep -v 'performance_schema\|information_schema')"
DATE=$(date +'%F')
MIN_BACKUP=1000 # NOTE: 1 Kilobit = 1000 bit
DAYS_KEPT=30

## Send result email can be toggled on or off
SEND_EMAIL=0
NOTIFY_EMAIL="somemail@example.com"
NOTIFY_SUBJECT="MariaDB Backup Notification on ${HOST}"

## Linux bin paths
MYSQLDUMP=$(command -v mysqldump)
GREP=$(command -v grep)
CHOWN=$(command -v chown)
CHMOD=$(command -v chmod)
GZIP=$(command -v gzip)
MAIL=$(command -v mail)
FIND=$(command -v find)
DF=$(command -v df)
FREE=$(command -v free)
DU=$(command -v du)

## Function for generating Email
function gen_email {
    local DO_SEND=$1
    local TMP_FILE=$2
    local NEW_LINE=$3
    local LINE=$4
    if [ "$DO_SEND" -eq 1 ]; then
        if [ "$NEW_LINE" -eq 1 ]; then
            echo "$LINE" >> "$TMP_FILE"
        else
            echo -n "$LINE" >> "$TMP_FILE"
        fi
    fi
}

## Temp Message file used for recording data on backup and cleanup
TMP_MSG_FILE="/tmp/$RANDOM.msg"
if [ "$SEND_EMAIL" -eq 1 ] && [ -f "$TMP_MSG_FILE" ]; then
    rm -f "$TMP_MSG_FILE"
fi

set -o pipefail

## Check if destination dir exists, create if not
[ -d "$DEST" ] || mkdir -p "$DEST"

## Start backing up databases and check if today's backup already exists
STARTTIME=$(date +%s)
for db in "${DBS[@]}"; do
    skipdb=-1
    if [ -n "$NOBKDB" ]; then
        for i in $NOBKDB; do
            if [ "$db" == "$i" ]; then
                skipdb=1
                break
            fi
        done
    fi

    GZ_FILENAME="$HOST-$db-$DATE.sql.gz"

    if [[ -f "${DEST}${GZ_FILENAME}" ]]; then
        echo "Backup file ${DEST}$GZ_FILENAME already exists for today. Exiting."
        gen_email "$SEND_EMAIL" "$TMP_MSG_FILE" 1 "Error: Backup files ${DEST}$GZ_FILENAME: already exists for today."
    elif [ "$skipdb" == "-1" ]; then
        # Connect to MySQL using mysqldump for selected database
        mysqldump -u root --quote-names --opt --single-transaction --quick "$db" | gzip -cf > "${DEST}${GZ_FILENAME}"
        if [ $? -ne 0 ]; then
            NOTIFY_MESSAGE="Error while backing up database: $db"
            logger -i -t "${syslogtag}" "MySQL Database Backup FAILED; Database: $db"
        else
            NOTIFY_MESSAGE="Successfully backed up database: $db"
            logger -i -t "${syslogtag}" "MySQL Database Backup Successful; Database: $db"
        fi
        gen_email "$SEND_EMAIL" "$TMP_MSG_FILE" 1 "$NOTIFY_MESSAGE"
        echo "$NOTIFY_MESSAGE"
    fi
done

ENDTIME=$(date +%s)
DIFFTIME=$((ENDTIME - STARTTIME))
DUMPTIME="$((DIFFTIME / 60)) minutes and $((DIFFTIME % 60)) seconds."

## Log Time
gen_email "$SEND_EMAIL" "$TMP_MSG_FILE" 1 "mysqldump took: ${DUMPTIME}"
echo "mysqldump took: ${DUMPTIME}"

## Check backup file count
DATABASE_COUNT=$(mysql -u root -e 'show databases;' | grep -Ev '^Database$|hold$' | grep -vc 'performance_schema\|information_schema')
BACKUP_COUNT=$(find "$DEST" -maxdepth 1 -iname '*.gz' | wc -l)
if [ "$BACKUP_COUNT" -eq 0 ]; then
    NOTIFY_MESSAGE="No backup files exist in $DEST. Total files: $BACKUP_COUNT ERROR!!!!"
    gen_email "$SEND_EMAIL" "$TMP_MSG_FILE" 1 "$NOTIFY_MESSAGE"
    echo "$NOTIFY_MESSAGE"
elif [ "$BACKUP_COUNT" -le $((DATABASE_COUNT * DAYS_KEPT)) ]; then
    NOTIFY_MESSAGE="Only found $BACKUP_COUNT backup files. No cleanup will be done at this time."
    gen_email "$SEND_EMAIL" "$TMP_MSG_FILE" 1 "$NOTIFY_MESSAGE"
    echo "$NOTIFY_MESSAGE"
else
    NOTIFY_MESSAGE="$BACKUP_COUNT backup files over the amount. Cleanup to occur on $DEST"
    gen_email "$SEND_EMAIL" "$TMP_MSG_FILE" 1 "$NOTIFY_MESSAGE"
    echo "$NOTIFY_MESSAGE"
fi

## Delete backups older than 30 days
TO_DELETE=$(find "$DEST" -maxdepth 1 -type f -iname "*.sql.gz" -daystart -mtime +"$((DELETE_BACKUPS_OLDER_THAN_DAYS - 1))" -print | sort)
if [ -n "$TO_DELETE" ]; then
    echo "Deleting the following files: $TO_DELETE"
    echo "$TO_DELETE" | xargs rm
    echo "Files deleted."
else
    echo "No files to delete."
fi

## Check backup file size
for i in "${DEST}"*.sql.gz; do
    if [[ ! -f "${DEST}/${GZ_FILENAME}" ]]; then
        echo "Today's backup file, ${DEST}/${GZ_FILENAME}, not found."
        gen_email "$SEND_EMAIL" "$TMP_MSG_FILE" 1 "Today's backup file, ${DEST}/${GZ_FILENAME}, not found."
    fi

    SIZE_BYTES=$(stat -c%s "$i")
    SIZE=$((SIZE_BYTES + 512 / 1024))

    if [[ ! $SIZE -gt $MIN_BACKUP ]]; then
        echo "Backup file: ${i} is smaller than the expected size. Expecting > ${MIN_BACKUP} bit and got ${SIZE} bit"
        gen_email "$SEND_EMAIL" "$TMP_MSG_FILE" 1 "Backup file: ${i} is smaller than the expected size. Expecting > ${MIN_BACKUP} bit and got ${SIZE} bit"
    fi
done

## Disk space stats of backup file system
$DF -h "$DEST"

## List of current backup files
echo "List of current backup files: "
$DU -hsc --time --apparent-size "${DEST}"*

## Sending notification email and cleanup of temporary file
if [ "$SEND_EMAIL" -eq 1 ]; then
    $MAIL -s "$NOTIFY_SUBJECT" "$NOTIFY_EMAIL" < "$TMP_MSG_FILE"
    rm -f "$TMP_MSG_FILE"
fi

exit
