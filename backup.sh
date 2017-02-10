#!/bin/bash

# DESCRIPTION: 	This script makes a backup copy of the project zipped with time stamp into a local backup directory
# AUTHOR:   	Roman Kharkovski (http://whywebsphere.com/)

SOURCE=/home/ubuntu/workspace
DEST=/home/ubuntu/archive
if [ ! -d "$DEST" ]; then
	mkdir $DEST
fi

BACKUP_FILE=$DEST/backup_`date +%s`
echo "Making new backup of the '$SOURCE' into the '$BACKUP_FILE'..."
cp -r $SOURCE $BACKUP_FILE
echo "Backup complete. Content of the $DEST folder is listed below:"
dir -l -t $DEST