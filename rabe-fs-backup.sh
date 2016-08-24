#!/bin/bash
#
#    This file is part of `Radio RaBe Backup process and automation scripts`
#    Copyright (C) 2016 Radio Bern RaBe
#    https://github.com/radiorabe/backup
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Constants --------------------------------------------------------------------
#
TMPDIR=/tmp					# here to put temporary files
DEBUG=0						# debug level 0-3
VERBOSE=3					# verbosity level
CONFIG_DIR=/etc/`basename "$0" .sh`		# config directory
BACKUP_SERVER=""				# loaded by config file
STD_RSYNC_OPTIONS="--verbose --archive --recursive --acls --devices \
--specials --delete --numeric-ids --timeout=120 --delete-excluded \
--stats --human-readable --inplace -n"
STD_BACKUP_DIRS="/etc /home /root /srv /usr/local /var/log /var/local /var/spool /var/backup"
BIN_SSH=`which ssh`				# find path to ssh
STD_SSH_OPTIONS="PasswordAuthentication=no"	# only with publickey
BIN_RSYNC=`which rsync`				# find path to ssh

logging()
#
# Description:  It writes messages to logfile or standard output.
#
# Parameter  :  $1 - the level of message
#               $2 - the message
#
# Std. Output:  Logging messages.
#
{
 if [ $DEBUG -ge 3 ]; then set -x
 fi

 logtime="$(date +%H):$(date +%M):$(date +%S)"
 prefix=""
 stderr=-1

 case $1 in
   -e)     prefix="Error:   " stderr=1 verbose=0;; #show always
   -s)     prefix="Success: " stderr=0 verbose=0;; #show always
   -r)     prefix="Stream:  " stderr=0 verbose=0;; #show always
   -i)     prefix="Info:    " stderr=0 verbose=1;; #show in VERBOSE>=1 mode
   -a)     prefix="         " stderr=0 verbose=1;; #show in VERBOSE>=1 mode
   -n)     prefix="Notice:  " stderr=0 verbose=2;; #show in VERBOSE>1 mode
   -w)     prefix="Warning: " stderr=1 verbose=2;; #show in VERBOSE>1 mode
   -d)     prefix="Debug:   " stderr=1 verbose=3;; #show only in DEBUG mode
 esac
 shift

# if VERBOSE mode is set, then show all messages, which we want to show in verbose mode
if [ $VERBOSE -ge 1 ] && [ $verbose -lt 2 ] ; then 
 if [ "$stderr" -eq 1 ]; then
   echo "$logtime $prefix" $1 >&2
 else
   echo "$logtime $prefix" $1
 fi
elif [ $VERBOSE -gt 1 ] && [ $verbose -lt 3 ] ; then 
 if [ "$stderr" -eq 1 ]; then
   echo "$logtime $prefix" $1 >&2
 else
   echo "$logtime $prefix" $1
 fi
# else show only messages which are defined to show in non-verbose mode
elif [ $verbose -eq 0 ] ; then
 if [ "$stderr" -eq 1 ]; then
   echo "$logtime $prefix" $1 >&2
 else
   echo "$logtime $prefix" $1
 fi
fi
# show debug messages
if [ $DEBUG -ge 1 ] && [ $verbose -eq 3 ] ; then
   echo "$logtime $prefix" $1 >&2
fi
}

checkRequirements()
#
# Description:  Check if all necessary tools and binaries are available
# 
# Parameter  :  none
#
# Output     :  logging
#               forces an error if a needed binary is not available
#
{
if [ $DEBUG -ge 3 ]; then set -x
fi

logging -d "Checking backup script requirements"

if [ -z $BIN_RSYNC ]; then RequirementsMsg=rsync
fi
if [ -z $BIN_SSH ]; then RequirementsMsg=ssh
fi

if [ ! -z $RequirementsMsg ];
then
  logging -e "Program $RequirementsMsg not installed or not in PATH"
  return 1
fi

if [ ! -d $CONFIG_DIR ]; then
  logging -e "Config dir $CONFIG_DIR does not exist."
  return 1
fi

return 0
}

shutdown_backup()
#
# Description:  shutting down backup and cleaning up
# 
# Parameter  :  none
#
# Output     :  logging
#
{
if [ $DEBUG -ge 3 ]; then set -x
fi

logging -n "Shutting down backup..."
ExitCode=$1

case $ExitCode in
	0)
	  logging -s "backup exiting..."
	;;
	1)
	  logging -w "backup stopped partionally unsuccuessfull"
	;;
esac
logging -d "Returnvalue=$ExitCode"

exit $ExitCode
}

load_config()
#
# Description:  load config files
#
# Parameter  :  none
#
# Output     :  none
#
{
if [ $DEBUG -ge 3 ]; then set -x
fi

local config_file=${CONFIG_DIR}/`basename $0 .sh`.conf

if [ ! -r ${config_file} ];
then
  echo Config file ${config_file} not found
  shutdown_backup
fi

. ${config_file}

}

check_backupserver()
#
# Description:  Check if backup server is reachable
#
# Parameter  :  none
#
# Output     :  exit code
#
{

# Validate destination path variable
if [ -z $BACKUP_SERVER ]; then
  logging -e "Oops! Backup server is not set."
  return 1
fi

if $BIN_SSH -O ${STD_SSH_OPTIONS} root@${BACKUP_SERVER} ls -1 &>/dev/null;
then
  logging -n "Backup server $BACKUP_SERVER found and reachable"
  return 0
else
  return 1
fi

}

backup_filesystems()
#
# Description:  Backing up std filesystems
#
# Parameter  :  none
#
# Output     :  exit code
#
{

local dirs_to_backup="$1"
logging -n "backup_filesystems(): Dirs to backup $dirs_to_backup"

if ! check_backupserver;
then
  logging -e "Oops! Problem with backup server"
  return 1
fi


}

sync_one_filesystem()
#
# Description:  backp/sync /boot partition
#
# Parameter  :  none
#
# Output     :  exit code
#
{

local sourcePath="$1"
local destinationHost="$2"
local destinationPath="$3"
local destinationRsync="${2}:${3}"

logging -n "sync_one_filesystem(): Validate config"

# Validate source path variable
if [ ! -d $sourcePath ]; then
  logging -e "sourcePath $sourcePath is not valid"
  return 1
fi

# Validate destination path variable
if [ -z $destinationPath ]; then
  logging -e "destinationPath is empty"
  return 1
fi

# Validate destination host variable
if [ -z $destinationHost ]; then
  logging -e "destinationHost is empty"
  return 1
fi

logging -n "sync_one_filesystem(): Syncing from $sourcePath to $destinationRsync"

# Validate destination path
if ! $BIN_SSH $destinationHost ls -1 $destinationPath; then
  logging -e "Backup destination $destinationPath on host $destinationHost does not exist!"
  logging -a "Check rsync error messages!"
  return 1
fi

logging -i "Syncing $HOSTNAME:$sourcePath to $destinationPath"

$BIN_RSYNC	--verbose \
		--archive \
		--recursive \
		--acls \
		--devices \
		--specials \
		--rsh=$BIN_SSH \
		--delete \
		--exclude="profiles/*" \
		--numeric-ids \
		--timeout=120 \
		--delete-excluded \
		--stats \
		--human-readable \
		-n
		#--progress \
		#--bwlimit=8000 \
		--inplace \
               ${sourcePath} ${destinationPath}

return $?
}

# CheckRequirements before do anything
if ! checkRequirements; then shutdown_backup 1
fi

load_config

logging -i "Starting backup at `hostname --fqdn`"
backup_filesystems "$STD_BACKUP_DIRS"
