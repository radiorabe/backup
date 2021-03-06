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
BACKUP_SRC_HOST="vm-0018.vm-admin.int.rabe.ch"
BACKUP_SRC_DIRS=(
    '/vservers/hq.rabe.ch/samba-01/home/'
    '/vservers/hq.rabe.ch/samba-01/music/'
    '/vservers/hq.rabe.ch/samba-01/shares/'
    '/vservers/hq.rabe.ch/samba-01/transfer/'
    )
BACKUP_DST_DIRS=(
    '/srv/backup/homes'
    '/srv/backup/music'
    '/srv/backup/shares'
    '/srv/backup/transfer'
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
  logging -w "Backup start time was not set!"
  return 1
fi

zabbixHostName=$( ssh -i ${SSH_KEY} ${SSH_USER}@${vm_name} \
    grep -Po "'(?<=^Hostname=).*'" \
      /etc/zabbix/zabbix_agentd.conf)

if [ -z $zabbixHostName ];
then
  logging -w "Could not recognize zabbix hostname!"
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
logging -n "rabe-backup CTRL-C catched"
exit 1
}

# Main -------------------------------------------------------------------------

# Source logging: https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. $SCRIPT_DIR/logging.lib

# Configure rsync --bwlimit if backup is executed during the day
BW_LIMIT_HOUR="`date +%H`"
if [ "$BW_LIMIT_HOUR" -ge 7 -a "$BW_LIMIT_HOUR" -le 23 ];
then
    logging -i "Starting backup with limited bandwidth - 100 MBit/s"
    RSYNC_OPTS="$RSYNC_OPTS --bwlimit=10240"
fi

mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bkp

logging -i "rabe-backup rsync backup of userdata starting."

startTime="$(date +%s)";
vm_name=".vm-admin.int.rabe.ch";
errors=0;
ssh-keyscan $BACKUP_SRC_HOST >> ~/.ssh/known_hosts 2>/dev/null

i=0
until [ -z ${BACKUP_SRC_DIRS[i]} ];
do

syncdir="${BACKUP_SRC_HOST}:${BACKUP_SRC_DIRS[i]}"

if [ ! -d ${BACKUP_DST_DIRS[i]} ];
then
    logging -e "Destination ${BACKUP_DST_DIRS[i]} is not a directory"
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
  logging -s "Sync of $syncdir to ${BACKUP_DST_DIRS[i]} successfull!"
elif [ $ret -eq "23" ]
then
  logging -i "$syncdir does not exist."
elif [ $ret -eq "12" ]
then
  logging -e "Permission denied on $syncdir."
  let "errors++";
elif [ $ret -eq "255" ]
then
  logging -e "Host $i.vm-admin.int.rabe.ch is not online or could not be resolved."
  let "errors++";
else
 logging -e "Unknown error ($ret) occured when trying to rsync $syncdir."
 let "errors++";
fi

i=$(( $i + 1 ))
done

if [ $errors -eq 0 ];
then
  if ! backup_success $startTime;
  then
      logging -e "backup_success: Could not send statuses for ${zabbixHostName} to zabbix"
  fi
else
  let "errors_vm_all++";
  logging -w "$vm_name had problems during the backup job."
fi

mv ~/.ssh/known_hosts.bkp ~/.ssh/known_hosts
logging -i "Script finished; $errors occured during the backup job."

if [ $errors -gt 0 ];
then
  exit 1
fi
