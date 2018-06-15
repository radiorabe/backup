#!/bin/bash

PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/scripts/backup"

RetVal=0

echo "$(date): rabe-backup started"

backup-appliances.sh || RetVal=$?
backup-fs-vms.sh || RetVal=$?

if btrbk run;
then
  RetVal=$?
  echo "$(date): btrfs snapshot (btrbk) success."
else
  RetVal=$?
  echo "$(date): btrfs snapshot (btrbk) failed."
fi

echo "rabe-backup finished; script returnvalue=${RetVal}"
exit $RetVal
