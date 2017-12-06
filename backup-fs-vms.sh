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
BACKUP_DIRS="etc home root usr/local var/log var/local var/spool var/backup"
BACKUP_DST_DIR=/srv/backup/remote-backup
VMS=("vm-0001" "vm-0002" "vm-0003" "vm-0005" "vm-0006" "vm-0007" "vm-0008" "vm-0009" "vm-0010" "vm-0011" "vm-0012" "vm-0013" "vm-0014" "vm-0015" "vm-0016" "vm-0017" "***REMOVED***" "vm-0019" "vm-0020" "vm-0021")

function backup_success()
{

zabbixHostName=$(echo $1 | sed 's/vm-admin/service/g');
startTime=$2;

if [ -z $startTime ];
then
  echo "$(date) WARNING: Backup start time was not set!"
  return 1
fi

if [ -z $zabbixHostName ];
then
  echo "$(date) WARNING: habbixHostName for success message not set!"
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

# Sent output to logfile
exec 1>${LOGFILE}
exec 2>&1

mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bkp

echo "$(date): Rsync backup of VMS starting."

for i in "${VMS[@]}"
do
  startTime="$(date +%s)";
  vm_name="$i.***REMOVED***";
  errors=0;
  ssh-keyscan $i.***REMOVED*** >> ~/.ssh/known_hosts 2>/dev/null
  for j in $BACKUP_DIRS
  do
  syncdir=$i.***REMOVED***:/$j
  rsync --rsync-path="sudo /bin/rsync" \
	  --verbose \
          --archive \
          --recursive \
          --acls \
          --xattrs \
          --devices \
          --specials \
          --rsh="/usr/bin/ssh -i /home/backup/.ssh/id_rsa -l backup" \
          --delete \
          --numeric-ids \
          --timeout=120 \
          --stats \
          --human-readable \
          --progress \
          --inplace \
          --one-file-system \
          $syncdir ${BACKUP_DST_DIR}/${i} &>/dev/null
  ret=$?
  if [ $ret -eq "0" ]
  then
    echo "Sync of $syncdir to ${BACKUP_DST_DIR}/${i} successfull!"
  elif [ $ret -eq "23" ]
  then
    echo "INFO: $syncdir does not exist."
  elif [ $ret -eq "12" ]
  then
    echo "ERROR: Permission denied on $syncdir."
    let "errors++";
  elif [ $ret -eq "255" ]
  then
    echo "ERROR: Host $i.***REMOVED*** is not online or could not be resolved."
    let "errors++";
  else
   echo "ERROR: Unknown error ($ret) occured when trying to rsync $syncdir."
   let "errors++";
  fi
  done

if [ $errors -eq 0 ];
then
  backup_success $vm_name $startTime
fi

done
echo "$(date): Rsync backup finished."

if btrbk run;
then
  echo "$(date): btrfs snapshot (btrbk) finished."
else
  let "errors++";
fi

mv ~/.ssh/known_hosts.bkp ~/.ssh/known_hosts
echo "$(date): Script finished; $errors errors occured."

if [ $errors -gt 0 ];
then
  exit 1
fi
