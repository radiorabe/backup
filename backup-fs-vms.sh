#!/bin/sh

vms=("vm-0001" "vm-0002" "vm-0003" "vm-0005" "vm-0006" "vm-0007" "vm-0008" "vm-0009" "vm-0010" "vm-0011" "vm-0012" "vm-0013" "vm-0014" "vm-0015" "vm-0016" "vm-0017" "***REMOVED***" "vm-0019" "vm-0020" "vm-0021")

mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bkp

echo "$(date): Rsync backup of vms starting."

for i in "${vms[@]}"
do
  ssh-keyscan $i.***REMOVED*** >> ~/.ssh/known_hosts 2>/dev/null
  [ ! -d "$i" ] && mkdir $i
  cd $i
  for j in etc home root usr/local var/log var/local var/spool var/backup
  do
  syncdir=$i.***REMOVED***:/$j
  rsync --rsync-path="sudo /bin/rsync" -azR $syncdir ./ &>/dev/null
  ret=$?
  if [ $ret -eq "0" ]
  then
    echo "Sync of $syncdir successfull!"
  elif [ $ret -eq "23" ]
  then
    echo "INFO: $syncdir does not exist."
  elif [ $ret -eq "12" ]
  then
    echo "ERROR: Permission denied on $syncdir."
  elif [ $ret -eq "255" ]
  then
    echo "ERROR: Host $i.***REMOVED*** is not online or could not be resolved."
  else
   echo "ERROR: Unknown error ($ret) occured when trying to rsync $syncdir."
  fi
  done
  cd ..
done

echo "$(date): Rsync backup finished."

mv ~/.ssh/known_hosts.bkp ~/.ssh/known_hosts
