#!/bin/bash

## Variables
HOST=$(hostname -s)
DELETE_BACKUPS_OLDER_THAN_DAYS=30
syslogtag=MySQL-Backup
DEST=/backup/
DBS="$(mysql -u root -Bse 'show databases' | egrep -v '^Database$|hold$' | grep -v 'performance_schema\|information_schema')"
DATE=$(date +'%F')
MIN_BACKUP=1000 #NOTE: 1 Kilobit = 1000 bit
DAYS_KEPT=30

## Backup all existing databases.  Currently disabled, can be enabled to backup certain individual databases.
#DBS="$($MYSQL -u $MyUSER -h $MyHOST -p$MyPASS -Bse 'show databases')"
#DBS="$(mysql -u root -Bse 'show databases' | egrep -v '^Database$|hold$' | grep -v 'performance_schema\|information_schema')"
## Or specify which databases to backup
#DBS="mysql zarafa"

## DO NOT BACKUP these databases.  Currently disabled, can be enabled to not backup certain individual databases.
#NOBKDB="test"

## Send result email can be toggled on or off
SEND_EMAIL=0
NOTIFY_EMAIL="admin@minebest.com"
NOTIFY_SUBJECT="MariaDB Backup Notification on ${HOST}"

## Linux bin paths
MYSQLDUMP="$(which mysqldump)"
GREP="$(which grep)"
CHOWN="$(which chown)"
CHMOD="$(which chmod)"
GZIP="$(which gzip)"
MAIL="$(which mail)"
FIND="$(which find)"
DF="$(which df)"
FREE="$(which free)"
DU="$(which du)"

## Function for generating Email
function gen_email {
    DO_SEND=$1
    TMP_FILE=$2
    NEW_LINE=$3
    LINE=$4
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
if [ $SEND_EMAIL -eq 1 -a -f "$TMP_MSG_FILE" ]; then
  rm -f "$TMP_MSG_FILE"
fi

set -o pipefail

## check if destination dir exists, create if not
[ -d $DEST ] && mkdir -p "$DEST"
  
## Start backing up databases and check if today's backup already exists
STARTTIME=$(date +%s)
for db in ${DBS[@]};
do  

skipdb=-1
if  [ "$NOBKDB" != "" ];
then
for i in $NOBKDB
do
    [ "$db" == "$i" ] && skipdb=1 || :
done
fi

    GZ_FILENAME=$HOST-$db-$DATE.sql.gz

    if [[ -f ${DEST}${GZ_FILENAME} ]]; then 
    echo "Backup file ${DEST}$GZ_FILENAME already exists for today. Exiting."
    gen_email $SEND_EMAIL $TMP_MSG_FILE 1 "Error: Backup files ${DEST}$GZ_FILENAME: already exists for today."
    elif  [ "$skipdb" == "-1" ] ; then
    # connect to mysql using mysqldump for select mysql database
    # and pipe it out to gz file in backup dir
    mysqldump -u root --quote-names --opt --single-transaction --quick "$db" | gzip -cf > $DEST"$HOST"-"$db"-"$DATE".sql.gz
    ERR=$?
    if [ $ERR != 0 ]; then
    NOTIFY_MESSAGE="Error: $ERR, while backing up database: $db"
    logger -i -t ${syslogtag} "MySQL Database Backup FAILED; Database: $db"
    else
    NOTIFY_MESSAGE="Successfully backed up database: $db "
    logger -i -t ${syslogtag} "MySQL Database Backup Successful; Database: $db"
    fi
    gen_email $SEND_EMAIL $TMP_MSG_FILE 1 "$NOTIFY_MESSAGE"
    echo "$NOTIFY_MESSAGE"
    fi
done

ENDTIME=$(date +%s)
DIFFTIME=$(( $ENDTIME - $STARTTIME ))
DUMPTIME="$(($DIFFTIME / 60)) minutes and $(($DIFFTIME % 60)) seconds."

## Empty line in email and stdout
gen_email $SEND_EMAIL $TMP_MSG_FILE 1 ""
echo ""

## Log Time
gen_email $SEND_EMAIL $TMP_MSG_FILE 1 "mysqldump took: ${DUMPTIME}"
echo "mysqldump took: ${DUMPTIME}"

## Empty line in email and stdout
gen_email $SEND_EMAIL $TMP_MSG_FILE 1 ""
echo ""

## Make sure we have a minimum number of files.  If we don't than e-mail.
DATABASE_COUNT=$(mysql -u root -e 'show databases;' | egrep -v '^Database$|hold$' | grep -v 'performance_schema\|information_schema'| wc -l)
BACKUP_COUNT=$(find ${DEST} -maxdepth 1 -iname '*.gz' | wc -l)
if [ "$BACKUP_COUNT" -eq 0 ] 
then
NOTIFY_MESSAGE="No backup files exist in $DEST. total files: $BACKUP_COUNT  ERROR!!!!"
gen_email $SEND_EMAIL $TMP_MSG_FILE 1 "$NOTIFY_MESSAGE"
echo "$NOTIFY_MESSAGE"
elif  [ "$BACKUP_COUNT" -le  $((($DATABASE_COUNT) * ${DAYS_KEPT})) ]
then
NOTIFY_MESSAGE="Only found $BACKUP_COUNT backup files. No cleanup will be done at this time.";
gen_email $SEND_EMAIL $TMP_MSG_FILE 1 "$NOTIFY_MESSAGE"
echo "$NOTIFY_MESSAGE"
elif [ "$BACKUP_COUNT" -gt $((($DATABASE_COUNT) * ${DAYS_KEPT})) ]
then
NOTIFY_MESSAGE="$BACKUP_COUNT backup files over the amount. Cleanup to occur on $DEST"
gen_email $SEND_EMAIL $TMP_MSG_FILE 1 "$NOTIFY_MESSAGE"
echo "$NOTIFY_MESSAGE"
fi

## Empty line in email and stdout
gen_email $SEND_EMAIL $TMP_MSG_FILE 1 ""
echo ""

## Delete backups older than 30 days
total_backup=$(ls -tr $DEST | wc -l)
TO_DELETE=$(find ${DEST} -maxdepth 1 -type f -iname "*.sql.gz" -daystart -mtime +$(($DELETE_BACKUPS_OLDER_THAN_DAYS-1)) -print | sort | head -n "$total_backup")
if [ -n "$TO_DELETE" ]
then
echo "Deleting the following files: $TO_DELETE"
NOTIFY_MESSAGE="Deleting the following files: $TO_DELETE "
gen_email $SEND_EMAIL $TMP_MSG_FILE 1 "Deleting: $TO_DELETE: "
echo "$TO_DELETE" | xargs rm
echo "Files deleted."
NOTIFY_MESSAGE="OK: Files deleted."
else
NOTIFY_MESSAGE="No files to delete."
fi

gen_email $SEND_EMAIL $TMP_MSG_FILE 1 "$NOTIFY_MESSAGE"
echo "$NOTIFY_MESSAGE"


## Empty line in email and stdout
gen_email $SEND_EMAIL $TMP_MSG_FILE 1 ""
echo ""

for i in ${DEST}*.sql.gz
do
    ## Check to make sure we have a backup from today. If we don't then e-mail
    if [[ ! -f ${DEST}/${GZ_FILENAME} ]]; then 
        echo "Today's backup file, ${DEST}/${GZ_FILENAME}, not found.";
        NOTIFY_MESSAGE="Today's backup file, ${DEST}/${GZ_FILENAME}, not found.";
        gen_email $SEND_EMAIL $TMP_MSG_FILE 1 "$NOTIFY_MESSAGE" 
    fi

    ## Make sure the backups has some reasonable size to it. If it doesn't then e-mail
    SIZE_BYTES=$(stat -c%s "${i}" )
    SIZE=$(( SIZE_BYTES + 512 / 1024 ))
    
    if [[ ! $SIZE -gt $MIN_BACKUP ]]; then
        echo "Backup file: ${i} is smaller than the expected size.  Expecting > ${MIN_BACKUP} bit and got ${SIZE} bit";
        NOTIFY_MESSAGE="Backup file: ${i} is smaller than the expected size.  Expecting > ${MIN_BACKUP} bit and got ${SIZE} bit";
        gen_email $SEND_EMAIL $TMP_MSG_FILE 1 "$NOTIFY_MESSAGE" 
    fi
done

## Empty line in email and stdout
gen_email $SEND_EMAIL $TMP_MSG_FILE 1 ""
echo ""

## Disk space stats of backup file system
if [ $SEND_EMAIL -eq 1 ]; then
    $DF -h "$DEST" >> "$TMP_MSG_FILE"  
fi
$DF -h "$DEST"

## Empty line in email and stdout
gen_email $SEND_EMAIL $TMP_MSG_FILE 1 ""
echo ""

## Empty line in email and stdout
gen_email $SEND_EMAIL $TMP_MSG_FILE 1 ""
echo ""

## List of current backup files email and stdout
gen_email $SEND_EMAIL $TMP_MSG_FILE 1 "List of current backup files: "
echo "List of current backup files: "
    if [ $SEND_EMAIL -eq 1 ]; then
        $DU -hsc --time --apparent-size ${DEST}* >> "$TMP_MSG_FILE"
    fi
$DU -hsc --time --apparent-size ${DEST}*

## Empty line in email and stdout
gen_email $SEND_EMAIL $TMP_MSG_FILE 1 ""
echo ""

## Sending notification email and cleanup of temporary file
if [ $SEND_EMAIL -eq 1 ]; then
    $MAIL -s "$NOTIFY_SUBJECT" "$NOTIFY_EMAIL" < "$TMP_MSG_FILE"
    rm -f "$TMP_MSG_FILE"
fi

exit
