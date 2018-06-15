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
RSYNC_OPTS="--verbose --archive --recursive --acls --xattrs --devices --specials --delete --numeric-ids --timeout=120 --stats --human-readable --progress --inplace --one-file-system" 

function get_vm_list()
{

local ovirt_url="https://***REMOVED***/ovirt-engine/api"
local ovirt_user="admin@internal"
local ovirt_password=`cat /home/backup/.ovirt_password`

local tmpVMS=`mktemp`

if ! curl \
  -s \
  --insecure \
  --header "Accept: application/xml" \
  --user "${ovirt_user}:${ovirt_password}" \
  "${ovirt_url}/vms" \
  | sed -n 's/<name>\(vm-.\{4\}\)<\/name>/\1/p' | tr -d '\n' >$tmpVMS;
then
  Ret=$?
  echo "$(date) ERROR: Cannot fetch list of VMs via ovirt api! Returnvalue=$Ret"
  exit $Ret
fi

# Split string into an array in Bash
# https://stackoverflow.com/questions/10586153/split-string-into-an-array-in-bash
read -r -a VMS <<< `cat $tmpVMS`
rm $tmpVMS
} # get_vm_list()

function backup_success()
{


startTime=$1;

if [ -z $startTime ];
then
  echo "$(date) WARNING: Backup start time was not set!"
  return 1
fi

zabbixHostName=$( ssh -i ${SSH_KEY} ${SSH_USER}@${vm_name} \
    grep -Po "'(?<=^Hostname=).*'" \
      /etc/zabbix/zabbix_agentd.conf)

if [ -z $zabbixHostName ];
then
  echo "$(date) WARNING: Could not recognize zabbix hostname!"
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
echo "$(date) CTRL-C catched"
exit 1
}

# Main -------------------------------------------------------------------------

get_vm_list

mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bkp

echo "$(date): Rsync backup of VMS starting."

errors_vm_all=0;
for i in "${VMS[@]}"
do
  startTime="$(date +%s)";
  vm_name="$i.***REMOVED***";
  errors_vm=0;
  ssh-keyscan $i.***REMOVED*** >> ~/.ssh/known_hosts 2>/dev/null
  for j in $BACKUP_DIRS
  do
  syncdir=$i.***REMOVED***:/$j
  rsync --rsync-path="sudo /bin/rsync" \
	--rsh="${RSH_CMD}" \
	${RSYNC_OPTS} \
        $syncdir ${BACKUP_DST_DIR}/${i}
  ret=$?
  if [ $ret -eq "0" ]
  then
    echo "$(date) Sync of $syncdir to ${BACKUP_DST_DIR}/${i} successfull!"
  elif [ $ret -eq "23" ]
  then
    echo "$(date) INFO: $syncdir does not exist."
  elif [ $ret -eq "12" ]
  then
    echo "$(date) ERROR: Permission denied on $syncdir."
    let "errors_vm++";
  elif [ $ret -eq "255" ]
  then
    echo "$(date) ERROR: Host $i.***REMOVED*** is not online or could not be resolved."
    let "errors_vm++";
  else
   echo "$(date) ERROR: Unknown error ($ret) occured when trying to rsync $syncdir."
   let "errors_vm++";
  fi
  done

if [ $errors_vm -eq 0 ];
then
  if ! backup_success $startTime;
  then
      echo "$(date) ERROR: backup_success: Could not send statuses for ${zabbixHostName} to zabbix"
  fi
else
  let "errors_vm_all++";
  echo "$(date) WARNING: $vm_name had problems during the backup job."
fi

done

mv ~/.ssh/known_hosts.bkp ~/.ssh/known_hosts
echo "$(date): Script finished; $errors_vm_all VMs had problems during the backup job."

if [ $errors_vm_all -gt 0 ];
then
  exit 1
fi
