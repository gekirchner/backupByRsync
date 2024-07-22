#!/bin/bash
#
# Version of this script
SCRIPT_VERSION="0.1"
# Absolute path to this script
PATH_AND_NAME_OF_SCRIPT=$(realpath "$0")
# Absolute path of this script's folder
SCRIPTPATH=$(dirname "$PATH_AND_NAME_OF_SCRIPT")

# Multiple used strings
TXT_prev_backup_found_for_usage="Previous backup found for usage of hard links of unchanged files:"
TXT_compl_backup_because_no_prev="Complete Backup necessary because no previous backup folder found. No usage of hard links."
TXT_backup_of_these_folders="Backup of these folders with all their subfolders:"
TXT_dest_folder_for_storing="Destination folder for storing the backup:"

###### Functions ######

function usage_of_script_main() {
  echo
  echo "usage: ./backupByRsync.bash [config_file] | -help"
  echo
  echo "This script performs a plain and simple data backup with usage of rsync tool."
  echo "A configuration file is needed which contains information about the sources and base destination of the backup."
  echo "If the parameter [config_file] is omitted, then a config file named \"backupConfig.bash\" is expected in the script's directory."
  echo "If possible, the backup creates hard links from a previous destination directory instead of copying files from source tree." 
  echo
}

#--------------

function script_help() {
  usage_of_script_main

  echo "Configuration File:"
  echo "  This script uses a configuration file in which source directory trees and base destination directory has to be entered."
  echo "  An example config file named \"backupConfig_example.bash\" exists in which such entries are shown."
  echo "  All files and directories below each directory tree entry in SOURCE_LIST are backed up to the base destination directory in DESTBASE."
  echo "  Limitations:"
  echo "    Entries in SOURCE_LIST must not have spaces. This means that no spaces are allowed in name of uppermost directory of a source tree."
  echo "    Entry   in DESTBASE    must not have spaces. This means that no spaces are allowed in name of uppermost directory of destination tree."
  echo "Backup Process:"
  echo "  For each run of this script, a new destination directory is created in base destination directory."
  echo "  The destination directories are named according date and time of creation: <YYYY>-<MM>-<DD>-<HH><MM>."
  echo "  A log file named \"log_<YYYY>-<MM>-<DD>-<HH><MM>.log\" is saved in the destination directory."
  echo "  The backup process is internally performed by rsync tool. The name of last valid destination directory is handed over to rsync."
  echo "  Whenever possible, hard links are created from last destination directory instead of a copy from source directory tree." 
  echo "  The destination directory name is expanded by \"-CORRUPT\" if the backup process failed."
  echo "  New runs do not use corrupt destination directories as basis of hard link creations but try to use a possible last valid destination dir." 
  echo "Pre-Requirement:"
  echo "  The rsync tool has to be installed before using this script."
  echo
}

#--------------

function echo_hint_help() {
  echo "For more information: Call script with parameter -help"
  echo
}

#--------------

function usage_of_script() {
  usage_of_script_main
  echo_hint_help
}

###### main program ######

# Initializations
PREVIOUS=""
answer_of_user="INIT_ANSWER"

# Plausibility check
if [ $# -gt 1 ]
then
  usage_of_script
  exit 1
fi

if [ "$1" == "-help" ] || [ "$1" == "--help" ] ||  [ "$1" == "-h" ] || [ "$1" == "--h" ]  
then
  script_help
  exit 0
fi

# Try to find rsync
which rsync &> /dev/null
if [ "$?" -ne 0 ]
then
  echo
  echo "ERROR: The tool \"rsync\" is obviously not installed!"
  echo_hint_help
  exit 1
fi  

# Find Config file
if [ $# -eq 0 ]
then
  CONFIG_FILE="$SCRIPTPATH/backupConfig.bash"
else
  CONFIG_FILE="$1"
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

# Where to find previous backup
ANY_BACKUP_FOLDER="$DESTBASE/????-??-??-????/"
ls -td $ANY_BACKUP_FOLDER &> /dev/null
if [ "$?" -eq 0 ]
then
  PREVIOUS=$(ls -td -- $ANY_BACKUP_FOLDER|head -n 1)
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
echo "---- (Restart this script with parameter \"-help\" for more infos) ----"
echo "---------------------------------------------------------------------"
echo ""
echo "CONFIG FILE = \"$CONFIG_FILE\""
echo ""

# Use previous backup as the incremental base if it exists
if [ -n "$PREVIOUS" ]
then
  echo "$TXT_prev_backup_found_for_usage"
  echo "PREVIOUS    = \"$PREVIOUS\""
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
echo "DEST        = \"$DEST\""
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
#echo "Test: SOURCE_LIST: "${SOURCE_LIST[*]}"" 
rsync -a --info=all4  --no-perms --no-owner --no-group --log-file="$LOGFILE" --link-dest "$PREVIOUS" ${SOURCE_LIST[*]} "$DEST"
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
if [ -z "$PREVIOUS" ]
then
  echo "$TXT_compl_backup_because_no_prev" >> "$LOGFILE"
else
  echo "$TXT_prev_backup_found_for_usage" >> "$LOGFILE"
  echo "PREVIOUS  = \"$PREVIOUS\"" >> "$LOGFILE"
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
echo "This config file was used: \"$CONFIG_FILE\"" >> "$LOGFILE"
echo "-------------------"    >> "$LOGFILE"
echo "" >> "$LOGFILE"

#Marking destination directory as corrupt in case of rsync error
if [ "$RSYNC_ERR" -ne 0 ]
then
  mv "$DEST" "$DEST-CORRUPT" 
fi

# Some variations which creates different output in log-file (unfortunately no info in log file when creating hardlink instead of copy)
#rsync -av  --no-perms --no-owner --no-group --log-file="$LOGFILE" --link-dest "$PREVIOUS" "$SOURCE1" "$SOURCE2" "$DEST"
#rsync -a --info=all4 --debug=all5  --no-perms --no-owner --no-group --log-file="$LOGFILE" --link-dest "$PREVIOUS" "$SOURCE1" "$SOURCE2" "$DEST"
#rsync -a --info=name4,stats3 --no-perms --no-owner --no-group --log-file="$LOGFILE" --link-dest "$PREVIOUS" "$SOURCE1" "$SOURCE2" "$DEST"
#rsync -avv --info=all4 --debug=all5  --no-perms --no-owner --no-group --log-file="$LOGFILE" --link-dest "$PREVIOUS" "$SOURCE1" "$SOURCE2" "$DEST"
