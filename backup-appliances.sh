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
LOGFILE="/var/log/${PN}.log"  # logfile.
BACKUP_DIRS="cf/conf/"
SSH_USER="backup"
SSH_KEY="/home/backup/.ssh/id_rsa"
RSH_CMD="/usr/bin/ssh -i ${SSH_KEY} -l ${SSH_USER}"
BACKUP_DST_DIR=/srv/backup/remote-backup
#APPLIANCE_LIST+=("gw-001.vm-admin.int.rabe.ch" "gw-002.vm-admin.int.rabe.ch" "ap-001.admin.int.rabe.ch")
APPLIANCE_LIST+=("gw-001.admin.int.rabe.ch" "gw-002.admin.int.rabe.ch" "ap-001.admin.int.rabe.ch")

function backup_success()
{


startTime=$2;

if [ -z $startTime ];
then
  echo "$(date) WARNING: Backup start time was not set!"
  return 1
fi

zabbixHostName=$1

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

mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bkp

echo "$(date): Appliance backup starting."

errors_vm_all=0;
for i in "${APPLIANCE_LIST[@]}"
do
  startTime="$(date +%s)";
  vm_name="$i";
  errors_vm=0;
  ssh-keyscan $vm_name >> ~/.ssh/known_hosts 2>/dev/null
  for j in $BACKUP_DIRS
  do
  syncdir=${vm_name}:/${j}
  set -x
  scp -qrpi ${SSH_KEY} ${SSH_USER}@${syncdir} ${BACKUP_DST_DIR}/${i}
  set +x
  ret=$?
  if [ $ret -eq "0" ]
  then
    echo "$(date) SUCCESS: Backup of $syncdir to ${BACKUP_DST_DIR}/${i} successfull!"
  else
   echo "$(date) ERROR: Unknown error ($ret) occured when trying to backup $syncdir."
   let "errors_vm++";
  fi
done

if [ $errors_vm -eq 0 ];
then
  if ! backup_success $vm_name $startTime;
  then
      echo "$(date) ERROR: backup_success: Could not send statuses for ${zabbixHostName} to zabbix"
  fi
else
  let "errors_vm_all++";
  echo "$(date) WARNING: $vm_name had problems during the backup job."
fi

done

mv ~/.ssh/known_hosts.bkp ~/.ssh/known_hosts
echo "$(date): Script finished; $errors_vm_all appliances had problems during the backup job."

if [ $errors_vm_all -gt 0 ];
then
  exit 1
fi
