#!/bin/bash

PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/scripts/backup"

RetVal=0

backup-appliances.sh || RetVal=$?
backup-fs-vms.sh || RetVal=$?

echo "Script returnvalue=${RetVal}"
exit $RetVal
