#!/bin/bash
PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/scripts/backup"

RetVal=0

echo "rabe-backup started"

backup-appliances.sh || RetVal=$?
backup-fs-vms.sh || RetVal=$?
btrbk run || RetVal=$?

echo "rabe-backup finished; script returnvalue=${RetVal}"

exit $RetVal
