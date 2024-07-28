# backupByRsync

Language:       Bourne Shell  
Version:        0.1

## Function:       
The shell script **backupByRsync.bash** performs a plain and simple data backup in a Linux environment with usage of *rsync* tool.  
A configuration file is needed which contains information about the sources and base destination of the backup. An example of a configuration file is provided and named "backupConfig_example.bash".  
If possible, the backup creates hard links from a previous destination directory instead of copying files from source tree.
This can tremendously save memory space and also process time.

## Installation:   
No installation is needed.
1. Simply copy the script "backupByRsync.bash" into your favorite folder.
2. Copy also the configuration file example "backupConfig_example.bash" into one of your accessible folders, e.g. in the same folder.
3. Afterwards uncomment the entries SOURCE_LIST and DESTBASE of "backupConfig_example.bash" and fill it with your specific needs:  
   - your source folder names (this means, which directories should be backed up) and  
   - your base destination folder name (this means, what is the destination of your backup).  
4. This changed file can then be saved as "backupConfig.bash" in the same directory in which the script "backupByRsync.bash" exists. But you also can give the configuration file an other filename than "backupConfig.bash" and save it in an other directory.
In this case, the configuration file's path and name has to be added as script parameter [config_file].  
5. Make sure that the files are executable (run *chmod +x \<filename\>* if necessary)

## Usage:          
   ``./backupByRsync.bash [config_file] | -help``

The parameter [config_file] stands for the folder and file name of the configuration file.  
If this parameter is omitted, then a config file named "backupConfig.bash" is expected in the script's directory.  
Starting the script with parameter "-help" shows additional informations about configuration file, backup process and pre-requirement.

## Limitations:
Entries in SOURCE_LIST must not have spaces. This means that no spaces are allowed in name of uppermost directory of a source tree.  
Entry   in DESTBASE    must not have spaces. This means that no spaces are allowed in name of uppermost directory of destination tree.

## Backup Process:
For each run of this script, a new destination directory is automatically created in base destination directory (DESTBASE).  
The destination directories are named according date and time of creation:  
"\<YYYY\>-\<MM\>-\<DD\>-\<HH\>\<MM\>"  
A log file named "log_\<YYYY\>-\<MM\>-\<DD\>-\<HH\>\<MM\>.log" is saved in the destination directory.  
The backup process is internally performed by *rsync* tool. The name of last valid destination directory is handed over to *rsync*. In doing so, hard links are created from last destination directory instead of a copy from source directory tree, whenever possible.  
The destination directory name is expanded by "-CORRUPT" if the backup process failed.
New runs do not use corrupt destination directories as basis of hard link creations but try to use a possible last valid destination folder.
 
## Pre-Requirement:
The *rsync* tool has to be installed before using this script.  
For successfully tests of this script, *rsync* version 3.2.7 was used by the author.


## License / Disclaimer:

This software is quite trivial (created by human intelligence without any AI :smile:) but nevertheless license and disclaimer information are added hereby:
 
MIT License
Copyright 2024 by gekirchner

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


## Third Party Software:

Thanks a lot to the authors of the brilliant *rsync* tool.  
The *rsync* tool is the absolute heart of this software.  
**Please refer to the *rsync* manpage for its license information.**
