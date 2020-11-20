#!/bin/bash
set -u
. "$(dirname "$0")/backup-util.sh"

PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/scripts/backup"
STEPS=(
  "backup-appliances.sh"
  "backup-fs-vms.sh"
  "backup-physical-servers.sh"
  "backup-userdata.sh"
  "btrbk run"
)

errs=0

log -i "Starting RaBe Backup"
for step in "${STEPS[@]}"; do
  $step
  ret="$?"
  log -i "$step finished; status=$ret"
  if [[ $ret -ne 0 ]]; then
    ((errs++))
  fi
done
log -i "$0 finished; errors=$errs"
# shellcheck disable=SC2086
exit $errs
# vim: tabstop=2 shiftwidth=2 expandtab
