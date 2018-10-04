#!/bin/sh
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
#
# Constants --------------------------------------------------------------------
#
BACKUP_SRC_HOST="***REMOVED***.***REMOVED***"
BACKUP_SRC_DIRS=(
    '***REMOVED***/'
    '/vservers/hq.rabe.ch/samba-01/var/samba/music_archive/mp3'
    '/vservers/hq.rabe.ch/samba-01/var/samba/music_archive/ra'
    '***REMOVED***/'
    '***REMOVED***/'
    '***REMOVED***/'
    )
BACKUP_DST_DIRS=(
    '***REMOVED***'
    '***REMOVED***_archive/mp3'
    '***REMOVED***_archive/ra'
    '***REMOVED***'
    '***REMOVED***'
    '***REMOVED***'
    )
SSH_USER="backup"
SSH_KEY="/home/backup/.ssh/id_rsa"
RSH_CMD="/usr/bin/ssh -i ${SSH_KEY} -l ${SSH_USER}"
BACKUP_DST_DIR=/srv/backup/remote-backup
RSYNC_OPTS="--archive --recursive --acls --devices --specials --delete --numeric-ids --timeout=120 --stats --human-readable --progress --inplace --one-file-system" 
#RSYNC_OPTS="--verbose --archive --recursive --acls --devices --specials --delete --numeric-ids --timeout=120 --stats --human-readable --progress --inplace --one-file-system" 


# Functions --------------------------------------------------------------------

function backup_success()
{


startTime=$1;

if [ -z $startTime ];
then
  echo "WARNING: Backup start time was not set!"
  return 1
fi

zabbixHostName=$( ssh -i ${SSH_KEY} ${SSH_USER}@${vm_name} \
    grep -Po "'(?<=^Hostname=).*'" \
      /etc/zabbix/zabbix_agentd.conf)

if [ -z $zabbixHostName ];
then
  echo "WARNING: Could not recognize zabbix hostname!"
  return 1
fi

timestamp=$(date +%s);
duration=$(($timestamp - $startTime));
Ret=0

# Send the timestamp of the last successfull backup
zabbix_sender --config /etc/zabbix/zabbix_agentd.conf \
              --host "${zabbixHostName}" \
              --key 'rabe.rabe-backup.run.success[]' \
              --value "$timestamp" || Ret=$?

# Send the duration of the last backup run in seconds
zabbix_sender --config /etc/zabbix/zabbix_agentd.conf \
              --host "${zabbixHostName}" \
              --key 'rabe.rabe-backup.run.duration[]' \
              --value "$duration" || Ret=$?

return $Ret;
}

# trap keyboard interrupt (control-c)
trap control_c SIGINT

control_c()
#
# Description:  run if user hits control-c
#
# Parameter  :  none
#
# Output     :  logging
#
{
echo "rabe-backup CTRL-C catched"
exit 1
}

# Main -------------------------------------------------------------------------

# Configure rsync --bwlimit if backup is executed during the day
BW_LIMIT_HOUR="`date +%H`"
if [ "$BW_LIMIT_HOUR" -ge 7 -a "$BW_LIMIT_HOUR" -le 23 ];
then
    echo "Starting backup with limited bandwidth - 100 MBit/s"
    RSYNC_OPTS="$RSYNC_OPTS --bwlimit=10240"
fi

mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bkp

echo "rabe-backup rsync backup of userdata starting."

startTime="$(date +%s)";
vm_name=".***REMOVED***";
errors=0;
ssh-keyscan $BACKUP_SRC_HOST >> ~/.ssh/known_hosts 2>/dev/null

i=0
until [ -z ${BACKUP_SRC_DIRS[i]} ];
do

syncdir="${BACKUP_SRC_HOST}:${BACKUP_SRC_DIRS[i]}"

if [ ! -d ${BACKUP_DST_DIRS[i]} ];
then
    echo "Error: Destination ${BACKUP_DST_DIRS[i]} is not a directory"
    break;
fi

set -x
rsync \
  --progress \
  --rsync-path="sudo /bin/rsync" \
  --rsh="${RSH_CMD}" \
  ${RSYNC_OPTS} \
  ${syncdir} ${BACKUP_DST_DIRS[i]}
set +x

ret=$?
if [ $ret -eq "0" ]
then
  echo "rabe-backup Sync of $syncdir to ${BACKUP_DST_DIRS[i]} successfull!"
elif [ $ret -eq "23" ]
then
  echo "rabe-backup INFO: $syncdir does not exist."
elif [ $ret -eq "12" ]
then
  echo "rabe-backup ERROR: Permission denied on $syncdir."
  let "errors++";
elif [ $ret -eq "255" ]
then
  echo "rabe-backup ERROR: Host $i.***REMOVED*** is not online or could not be resolved."
  let "errors++";
else
 echo "rabe-backup ERROR: Unknown error ($ret) occured when trying to rsync $syncdir."
 let "errors++";
fi

i=$(( $i + 1 ))
done

if [ $errors -eq 0 ];
then
  if ! backup_success $startTime;
  then
      echo "rabe-backup ERROR: backup_success: Could not send statuses for ${zabbixHostName} to zabbix"
  fi
else
  let "errors_vm_all++";
  echo "rabe-backup WARNING: $vm_name had problems during the backup job."
fi

mv ~/.ssh/known_hosts.bkp ~/.ssh/known_hosts
echo "rabe-backup: Script finished; $errors occured during the backup job."

if [ $errors -gt 0 ];
then
  exit 1
fi
