#!/bin/bash
# backup files from appliances
set -u
. "$(dirname "$0")/backup-util.sh"

APPLIANCE_LIST+=("***REMOVED***" "***REMOVED***" "***REMOVED***")
BACKUP_DIRS="home/backup/ cf/conf/ etc/icecast*"

# Main -------------------------------------------------------------------------

# Source logging: https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
. $SCRIPT_DIR/logging.lib

mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bkp

logging -i "Appliance backup starting."

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
  scp -rpi ${SSH_KEY} ${SSH_USER}@${syncdir} ${BACKUP_DST_DIR}/${i}
  set +x
  ret=$?
  if [ $ret -eq "0" ]
  then
    logging -s "Backup of $syncdir to ${BACKUP_DST_DIR}/${i} successfull!"
  else
   logging -e "Unknown error ($ret) occured when trying to backup $syncdir."
   let "errors_vm++";
  fi
done

if [ $errors_vm -eq 0 ];
then
  if ! backup_success $vm_name $startTime;
  then
      logging -e "Could not send statuses for ${zabbixHostName} to zabbix"
  fi
else
  let "errors_vm_all++";
  logging -w "$vm_name had problems during the backup job."
fi

done

mv ~/.ssh/known_hosts.bkp ~/.ssh/known_hosts
logging -i "Script finished; $errors_vm_all appliances had problems during the backup job."

if [ $errors_vm_all -gt 0 ];
then
  exit 1
fi
# vim: tabstop=2 shiftwidth=2 expandtab
