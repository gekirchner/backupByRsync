#!/bin/bash
#
##################################################################################
# This is the script "backupByRsync.bash".
# It includes a configuration file during execution.
# The script uses the rsync tool for performing a backup.
# For more information about the rsync tool, execute "man rsync" in Linux terminal.
##################################################################################
#
# Version of this script
SCRIPT_VERSION="0.2"
# Absolute path to this script
PATH_AND_NAME_OF_SCRIPT=$(realpath "$0")
# Absolute path of this script's folder
SCRIPTPATH=$(dirname "$PATH_AND_NAME_OF_SCRIPT")

# Multiple used strings
TXT_backup_found_for_hardlink_base="Previous backup found for usage of hard links of unchanged files:"
TXT_compl_backup_because_no_prev="Complete Backup necessary because no previous backup folder found. No usage of hard links."
TXT_backup_of_these_folders="Backup of these folders with all their subfolders:"
TXT_dest_folder_for_storing="Destination folder for storing the backup:"

###### Functions ######

function usage_of_script() {
  echo
  echo "Version: $SCRIPT_VERSION"
  echo
  echo "Usage: ./backupByRsync.bash  --help | -h"
  echo "       ./backupByRsync.bash [--config=FILE] [--base=DIR]"
  echo
  echo "Arguments (all optional):"
  echo "  --help, -h    : Help informations will be printed."
  echo
  echo "  --config=FILE : FILE is the configuration file. Default, if this argument is omitted: \"backupConfig.bash\" in the script's dir."
  echo
  echo "  --base=DIR    : DIR is the directory which is tried to be used as base for creating hardlinks instead of copying files."
  echo "                  Default, if this argument is omitted: The latest valid destination directory is tried to be used."
  echo
}

function script_help() {
  usage_of_script

  echo "Description:"
  echo "  This script performs a plain and simple data backup with usage of rsync tool."
  echo "  A configuration file contains the names of sources and base destination of the backup."
  echo "  The configuration file is given by the argument [--config=FILE]."
  echo "  If this argument is omitted, then a config file named \"backupConfig.bash\" is expected in the script's directory."
  echo "  If possible, the backup process creates hard links from a previous destination directory instead of copying files from source tree." 
  echo "  This previous destination directory is either given by [--base=DIR] or the latest valid destination directory is used."
  echo
  echo "Configuration File:"
  echo "  This script uses a configuration file in which names of source directory trees and base destination directory has to be entered."
  echo "  An example config file named \"backupConfig_example.bash\" exists in which such entries are shown."
  echo "  All files and directories below each directory tree entry in SOURCE_LIST are backed up to the base destination directory in DESTBASE."
  echo "  Limitations:"
  echo "    Entries in SOURCE_LIST must not have spaces. This means that no spaces are allowed in name of uppermost directory of a source tree."
  echo "    Entry   in DESTBASE    must not have spaces. This means that no spaces are allowed in name of base destination directory."
  echo
  echo "Backup Process:"
  echo "  For each run of this script, a new destination directory is created in base destination directory."
  echo "  The destination directories are named according date and time of creation: <YYYY>-<MM>-<DD>-<HH><MM>."
  echo "  A log file named \"log_<YYYY>-<MM>-<DD>-<HH><MM>.log\" is saved in the corresponding destination directory."
  echo "  The backup process is internally performed by rsync tool."
  echo "  Whenever possible, hard links are created from an existing destination directory instead of copying files from source directory tree." 
  echo "  By default, the latest existing destination directory is used as base for creating those hard links."
  echo "  But the optional argument [--base=DIR] allows the user to select an other directory as base for hard link creation."
  echo "  The destination directory name is expanded by \"-CORRUPT\" if the backup process ended with an error."
  echo "  By default, new runs do not use corrupt destination directories as basis of hard link creations but try to use the previous one." 
  echo
  echo "Pre-Requirement:"
  echo "  The rsync tool has to be installed before using this script."
  echo "  For successful tests of this script, rsync version 3.2.7 was used by the author."
  echo
  echo "Additional Informations:"
  echo "  - The script is backward compatible."
  echo "    This means e.g. that destination folders which were saved by V 0.1 of this script can also be used as base for creating hardlinks."
  echo "  - rsync is used as a local copy tool by this script. Nevertheless a remote backup is possible if a remote machine is connected by NFS."
  echo "    Backups can therefore be performed e.g. from a NAS to a PC or vice versa."
  echo "  - Tests have shown that a backup is successful not only to ext4 but also to ntfs partitions."
  echo "    (Of course, file name limitations for ntfs have to be considered)"  
  echo
  echo "Examples:"
  echo "  - Use the default configuration file ./backupConfig.bash and look for latest destination directory to create hardlinks:"
  echo "      ./backupByRsync"
  echo "  - Use the configuration file given by --config and look for latest destination directory to create hardlinks:"
  echo "      ./backupByRsync --config=/home/myname/work/myconfig"
  echo "  - Use the configuration file given by --config and look for the destination directory given by --base to create hardlinks:"
  echo "      ./backupByRsync --config=/home/myname/work/myconfig --base=/media/myData/2024-05-27-0934"
  echo
}

#--------------

function echo_hint_help() {
  echo "For more information: Call script with argument -h"
  echo
}

###### main program ######

# Initializations
BASE_FOR_HARDLINK=""
CONFIG_FILE="$SCRIPTPATH/backupConfig.bash"
answer_of_user="INIT_ANSWER"

# Plausibility check
if [ $# -gt 2 ]
then
  echo
  echo "argument plausiblitiy check failed!"
  echo
  echo_hint_help
  exit 1
fi

if [ "$1" == "--help" ] ||  [ "$1" == "-h" ]  
then
  script_help
  exit 0
fi

# Parsing optional arguments
for i in "$@"
do
  case $i in
    --config=* )
        CONFIG_FILE="${i#*=}"
        ;;
    --base=* )
        BASE_FOR_HARDLINK="${i#*=}"
        ;;
    * )
        echo "ERROR: Unknown argument $i"
        echo
        echo_hint_help
        exit 1
        ;;
  esac        
done

# Try to find rsync
which rsync &> /dev/null
if [ "$?" -ne 0 ]
then
  echo
  echo "ERROR: The tool \"rsync\" is obviously not installed!"
  echo
  echo_hint_help
  exit 1
fi  

if [ ! -e "$CONFIG_FILE" ]
then
  echo
  echo "ERROR: No access to config file \"$CONFIG_FILE\""
  echo
  echo_hint_help;
  exit 1
fi

# Include config file
. "$CONFIG_FILE"

# Check of SOURCE_LIST and DESTBASE in config file
if [ -z "$SOURCE_LIST" ] ||  [ -z "$DESTBASE" ]
then
  echo
  echo "ERROR: Empty SOURCE_LIST or DESTBASE in config file \"$CONFIG_FILE\""
  echo
  echo_hint_help;
  exit 1
fi

# Checks of SOURCE elements in config file
for i in "${SOURCE_LIST[@]}"
do
  # Check for spaces
  if [[ "$i" == *" "* ]]
  then
    echo
    echo "ERROR: \"$i\" not allowed because of space in directory name"
    echo "\"$CONFIG_FILE\" has to be corrected!"  
    echo
    echo_hint_help
    exit 1
  fi

  # Check for existence
  if [ ! -d "$i" ]
  then
    echo
    echo "ERROR: \"$i\" is no directory"
    echo "\"$CONFIG_FILE\" has to be corrected!"  
    echo
    echo_hint_help
    exit 1
  fi
done

# Checks of DESTBASE in config file
   # Check for spaces
   if [[ "$DESTBASE" == *" "* ]]
   then
     echo
     echo "ERROR: \"$DESTBASE\" not allowed because of space in directory name"
     echo "\"$CONFIG_FILE\" has to be corrected!"  
     echo
     echo_hint_help
     exit 1
   fi

   # Check accessibility of base destination folder
   if [ ! -d "$DESTBASE" ]
   then
     echo
     echo "ERROR: No access to backup base directory \"$DESTBASE\""
     echo
     echo_hint_help
     exit 1
   fi

# Base for hardlinks: Check for existence IN CASE OF argument passing 
if [ -n "$BASE_FOR_HARDLINK" ] && [ ! -d "$BASE_FOR_HARDLINK" ]
  then
     echo
     echo "ERROR: No access to hardlink base directory \"$BASE_FOR_HARDLINK\""
     echo
     echo_hint_help
     exit 1
fi

# Base for hardlinks: Find latest valid previous backup in case of NO argument passing 
if [ -z "$BASE_FOR_HARDLINK" ]
then
  ANY_BACKUP_FOLDER="$DESTBASE/????-??-??-????/"
  ls -td $ANY_BACKUP_FOLDER &> /dev/null
  if [ "$?" -eq 0 ]
   then
      BASE_FOR_HARDLINK=$(ls -td -- $ANY_BACKUP_FOLDER|head -n 1)
   fi    
fi

# Get the actual date and time
DATE_AND_TIME=$(date +%Y-%m-%d-%H%M)

# Folder for actual backup
DEST="$DESTBASE/$DATE_AND_TIME"

# Actual logfile
LOGFILE="$DEST/log_$DATE_AND_TIME.log"

# Show starting script
echo ""
echo "---------------------------------------------------------------------"
echo "Launching $PATH_AND_NAME_OF_SCRIPT"
echo "Version: $SCRIPT_VERSION"
echo "---------------------------------------------------------------------"
echo "---- This Script will perform a Data Backup with usage of rsync  ----"
echo "---- (Restart this script with argument \"-h\" for more infos)    ----"
echo "---------------------------------------------------------------------"
echo ""
echo "CONFIG FILE = \"$CONFIG_FILE\""
echo ""

# Use previous backup as the incremental base if it exists
if [ -n "$BASE_FOR_HARDLINK" ]
then
  echo "$TXT_backup_found_for_hardlink_base"
  echo "BASE_FOR_HARDLINK    = \"$BASE_FOR_HARDLINK\""
else
  echo "$TXT_compl_backup_because_no_prev"
fi
echo ""

# User can check settings before backup will be started
echo "$TXT_backup_of_these_folders"
cnt=0
for i in "${SOURCE_LIST[@]}"
do
  let cnt++
  echo "SOURCE_$cnt    = \"$i\""
done

echo ""
echo "$TXT_dest_folder_for_storing"
echo "DEST    = \"$DEST\""
echo ""
echo "LOGFILE = \"$LOGFILE\""
echo ""

while [ "$answer_of_user" != "y" ] && [ "$answer_of_user" != "n" ]
  do
    echo -n "proceed? [y | n] " 
    read answer_of_user
  done
if [ "$answer_of_user" == "n" ]
then
  echo ""
  exit 0
fi


# Check of already existing destination folder
ls "$DEST" &> /dev/null
if [ $? -eq 0 ]
then
  echo
  echo "ERROR: Destination folder already exists. Maybe trying two backups in one minute."
  echo
  echo_hint_help;
  exit 1
fi 

# create destination folder (otherwise log-file cannot be created by rsync. Reason: log-file is inside of $DEST)
mkdir "$DEST"

##### Run the rsync ####

#run rsync and add rsync errors in log file
rsync -a --info=all4  --no-perms --no-owner --no-group --log-file="$LOGFILE" --link-dest "$BASE_FOR_HARDLINK" ${SOURCE_LIST[*]} "$DEST" 2>> "$LOGFILE"

#some alternative rsync executions:
#quiet:
#rsync -aq --info=all4  --no-perms --no-owner --no-group --log-file="$LOGFILE" --link-dest "$BASE_FOR_HARDLINK" ${SOURCE_LIST[*]} "$DEST"

#dry-run:
#rsync -an --info=all4  --no-perms --no-owner --no-group --log-file="$LOGFILE" --link-dest "$BASE_FOR_HARDLINK" ${SOURCE_LIST[*]} "$DEST"

RSYNC_ERR="$?"
if [ "$RSYNC_ERR" -eq 0 ]
then
  RSYNC_TRANSFER_RESULT="rsync finished correctly - OK"
else
  RSYNC_TRANSFER_RESULT="ATTENTION: rsync finished with ERROR Code $RSYNC_ERR !"
fi  

# Add some infos to logfile
echo "" >> "$LOGFILE"
echo "------------------"    >> "$LOGFILE"
echo "- Script Summary -"    >> "$LOGFILE"
echo "------------------"    >> "$LOGFILE"
echo "" >> "$LOGFILE"
if [ -z "$BASE_FOR_HARDLINK" ]
then
  echo "$TXT_compl_backup_because_no_prev" >> "$LOGFILE"
else
  echo "$TXT_backup_found_for_hardlink_base" >> "$LOGFILE"
  echo "BASE_FOR_HARDLINK  = \"$BASE_FOR_HARDLINK\"" >> "$LOGFILE"
fi
echo "" >> "$LOGFILE"

echo "$TXT_backup_of_these_folders" >> "$LOGFILE"
cnt=0
for i in "${SOURCE_LIST[@]}"
do
  let cnt++
  echo "SOURCE_$cnt  = \"$i\""  >> "$LOGFILE"
done

echo "" >> "$LOGFILE"
echo "$TXT_dest_folder_for_storing" >> "$LOGFILE"
echo "DEST      = \"$DEST\""        >> "$LOGFILE"
echo "" >> "$LOGFILE"
echo "-------------------"    | tee -a "$LOGFILE"
echo "$RSYNC_TRANSFER_RESULT" | tee -a "$LOGFILE"
if [ "$RSYNC_ERR" -ne 0 ]
then
  echo "Marking destination directory as CORRUPT!" | tee -a "$LOGFILE"
  echo
  echo_hint_help;
fi
echo "-------------------"    | tee -a "$LOGFILE"
echo "This logfile was created by running of this script: \"$PATH_AND_NAME_OF_SCRIPT\"" >> "$LOGFILE"
echo "Script Version: $SCRIPT_VERSION" >> "$LOGFILE"
echo "This config file was used: \"$CONFIG_FILE\"" >> "$LOGFILE"
echo "-------------------"    >> "$LOGFILE"
echo "" >> "$LOGFILE"

#Marking destination directory as corrupt in case of rsync error
if [ "$RSYNC_ERR" -ne 0 ]
then
  mv "$DEST" "$DEST-CORRUPT" 
fi

