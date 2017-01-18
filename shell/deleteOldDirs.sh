#!/bin/bash

#
# GNRP LICENSE: Script licensed by GOD
#
# @author: Igor Ivanovski <igor at genrepsoft.com>
#
# July, 2014
#

#
# *** VARIABLES
#

PATH=$1 # First argument should be PATH of the backup folder
DAYS=$2 # Secound argument should be the max number of days we want to keep backups

GREP="/bin/grep"
MOUNT="/bin/mount"
FIND="/usr/bin/find"
RM="/bin/rm"

PATH_STATUS=0
MOUNT_STATUS=0

EXCLUDED_DIRS="/home/igor/Documents /home/igor/Programs"

#
# *** CHECKERS
#

if [ $# -eq 0 ]; then
    echo "No arguments provided"
    exit 1
fi

if [ -z $PATH ] || [ -z $DAYS ]; then
    echo "Not all arguments provided"
    exit 1
fi

#
# *** FUNCTIONS
#

function check_if_path_exists {

	[ ! -d $1 ] && echo "Path is invalild" || PATH_STATUS=1
}

function check_mount {
	 if [ -n "$($GREP $1 /etc/fstab)" ]; then
                echo "Mounting point exists..."
		if [ ! -n "$($MOUNT -l | $GREP $1)" ]; then
		    echo "...but not mounted."
		    echo "Mounting now."
                    $MOUNT $1
                    [ $? -eq 0 ] && { echo "Mounting was successfull!"; MOUNT_STATUS=1; } || echo "Can't mount";
		fi
         else
                echo "Mounting point doesn't exist"
         fi
}

# Excludes only if parent directory fits
function check_if_parent_dir_excluded { 
            for dir in $EXCLUDED_DIRS; do
		size=${#dir}
	        check=${1:0:size}
		#echo "$dir : ${#dir} == $check : ${#check}"
		if [ $dir ==  $check ]; then 
			echo "1"
		fi
	    done
}

function find_dirs {
	$FIND $PATH -mindepth 2 -maxdepth 2 -type d -ctime +$DAYS -print0
}

function print_dirs {
	while read -r n; do
                 result=$(check_if_parent_dir_excluded $n)
		 [ -z $result ] && printf '%q\n' "$n" || echo "Found EXCLUDE_DIR: $n" 
	done < <($FIND $PATH -mindepth 2 -maxdepth 2 -type d -ctime +$DAYS -print) # Use NL delimiter
}

function del_dirs {
        while read -r -d '' n; do
                 printf '%q\n' "$n"
                 result=$(check_if_parent_dir_excluded $n)
                 if [ -z $result ]; then
			 echo "Directory will be deleted now..."
			 $RM -rf $n
			 [ $? -eq 0 ] && echo "Gone!" || echo "Some error occured!"
		 else	
	 		echo "Found EXCLUDE_DIR: $n continue..." 
		 fi
        done < <($FIND $PATH -mindepth 2 -maxdepth 2 -type d -ctime +$DAYS -print0) # Use NUL delimiter
}

#
# *** MAIN
#

check_if_path_exists $PATH
[ $PATH_STATUS -eq 0 ] && check_mount $PATH
[ $MOUNT_STATUS -eq 1 ] && check_if_path_exists $PATH
[ $PATH_STATUS -eq 1 ] &&  del_dirs || { echo "Bye."; exit 0; }

#
# *** END
#
