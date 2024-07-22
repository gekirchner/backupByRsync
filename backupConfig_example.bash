################################################################################
# This is a configuration file example.
# This file should be adapted to the user's requirements:
# The SOURCE_LIST and DESTBASE have to be un-commented and filled with user's source folder names and base destination folder name.
# Afterwards this file can be saved as "backupConfig.bash" in the same directory in which the script "backupByRsync.bash" exists.
# The configuration file can also get an other filename than "backupConfig.bash" and can also be saved in another directory.
# The configuration file will automatically be included in the running script "backupByRsync.bash".
# If an other name and/or directory for this file was chosen, then the full configuration file's name has to be added as script parameter.
# For further informations execute "./backupByRsync.bash -help"
################################################################################
#
#Limitations: 
#   - Entries in SOURCE_LIST must not have spaces. This means that no spaces are allowed in name of uppermost directory of a source tree.
#   - Entry   in DESTBASE    must not have spaces. This means that no spaces are allowed in name of uppermost directory of destination tree.

#These folders have to be backed up with all their subfolders
#SOURCE_LIST=($HOME/myHomeData/projects\
#             /media/DataToBeSaved/myMediaFolder\
#             $HOME/myHomeData/hobby\
#             /tmp/someSubfolders\
#             $HOME/Phone/Music/Album)

#Base destination folder for storing the backup
#DESTBASE=/media/myBackups/savedByScript

