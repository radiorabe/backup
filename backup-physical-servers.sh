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
PN="`basename "$0" .sh`"
LOGFILE="/var/log/${PN}.log"  # rsync logfile.
BACKUP_DIRS="etc home root usr/local var/log var/local var/spool var/backup var/backups"
SSH_USER="backup"
SSH_KEY="/home/backup/.ssh/id_rsa"
RSH_CMD="/usr/bin/ssh -i ${SSH_KEY} -l ${SSH_USER}"
BACKUP_DST_DIR=/srv/backup/remote-backup
RSYNC_OPTS="--verbose --archive --recursive --acls --devices --specials --delete --numeric-ids --timeout=120 --stats --human-readable --progress --inplace --one-file-system" 
SERVERS_TO_BACKUP+=("***REMOVED***" "***REMOVED***" "***REMOVED***" "***REMOVED***")

if [[ "${DEBUG}" == 'true' ]]; then
  set -o xtrace
  RSYNC_OPTS="${RSYNC_OPTS} --dry-run"
fi

function backup_success()
{


startTime=$1;

if [ -z $startTime ];
then
  echo "WARNING: Backup start time was not set!"
  return 1
fi

zabbixHostName=$( ssh -i ${SSH_KEY} ${SSH_USER}@${client} \
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

echo "rabe-backup rsync backup of VMS starting."

errors_client_all=0;
for i in "${SERVERS_TO_BACKUP[@]}"
do
  startTime="$(date +%s)";
  client="$i";
  errors_client=0;
  ssh-keyscan $client >> ~/.ssh/known_hosts 2>/dev/null
  for j in $BACKUP_DIRS
  do
  syncdir=${client}:/${j}

# set -x
  rsync \
    --rsync-path="sudo /bin/rsync" \
    --rsh="${RSH_CMD}" \
    ${RSYNC_OPTS} \
    --xattrs \
    $syncdir ${BACKUP_DST_DIR}/${i}
# set +x

  ret=$?
  if [ $ret -eq "0" ]
  then
    echo "rabe-backup Sync of $syncdir to ${BACKUP_DST_DIR}/${i} successfull!"
  elif [ $ret -eq "23" ]
  then
    echo "rabe-backup INFO: $syncdir does not exist."
  elif [ $ret -eq "12" ]
  then
    echo "rabe-backup ERROR: Permission denied on $syncdir."
    let "errors_client++";
  elif [ $ret -eq "255" ]
  then
    echo "rabe-backup ERROR: Host $i.***REMOVED*** is not online or could not be resolved."
    let "errors_client++";
  else
   echo "rabe-backup ERROR: Unknown error ($ret) occured when trying to rsync $syncdir."
   let "errors_client++";
  fi
  done

if [ $errors_client -eq 0 ];
then
  if ! backup_success $startTime;
  then
      echo "rabe-backup ERROR: backup_success: Could not send statuses for ${zabbixHostName} to zabbix"
  fi
else
  let "errors_client_all++";
  echo "rabe-backup WARNING: $client had problems during the backup job."
fi

done

mv ~/.ssh/known_hosts.bkp ~/.ssh/known_hosts
echo "rabe-backup: Script finished; $errors_client_all VMs had problems during the backup job."

if [ $errors_client_all -gt 0 ];
then
  exit 1
fi
