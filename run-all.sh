#!/bin/bash
PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/scripts/backup"

RetVal=0

echo "rabe-backup started"

backup-appliances.sh || RetVal=$?
echo "backup-appliances.sh finished; status=${RetVal}"

backup-fs-vms.sh || RetVal=$?
echo "backup-fs-vms.sh finished; status=${RetVal}"

backup-physical-servers.sh || RetVal=$?
echo "backup-physical-servers.sh finished; status=${RetVal}"

backup-userdata.sh || RetVal=$?
echo "backup-userdata.sh finished; status=${RetVal}"

btrbk run || RetVal=$?
echo "btrbk run finished; status=${RetVal}"

echo "rabe-backup finished; script exitstatus=${RetVal}"

exit $RetVal
