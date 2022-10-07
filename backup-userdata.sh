#!/bin/bash
# backup user shares
. "$(dirname "$0")/backup-util.sh"

BACKUP_SRC_HOST="***REMOVED***.***REMOVED***"
BACKUP_SRC_DIRS=(
    "***REMOVED***/"
    "***REMOVED***/"
    "***REMOVED***/"
    "***REMOVED***/"
)
BACKUP_DST_DIRS=(
    "***REMOVED***"
    "***REMOVED***"
    "***REMOVED***"
    "***REMOVED***"
)

main(){
  log -i "Rsync backup of userdata starting"
  mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bkp
  ssh-keyscan "$BACKUP_SRC_HOST" >> ~/.ssh/known_hosts 2>/dev/null
  local errs=0
  local i=0
  for backup_src_dir in "${BACKUP_SRC_DIRS[@]}"; do
    local backup_dst_dir="${BACKUP_DST_DIRS[i]}"
    if [[ ! -d $backup_dst_dir ]]; then
       log -e "Destination $backup_dst_dir is not a directory"
       ((errs++))
    fi
    if ! do_rsync "$BACKUP_SRC_HOST:$backup_src_dir" "$backup_dst_dir" "--no-relative"; then
      ((errs++))
    fi
    ((i++))
  done
  mv ~/.ssh/known_hosts.bkp ~/.ssh/known_hosts
  log -i "Rsync backup user userdata finished with $errs problems"
  exit "$errs"
}
main
# vim: tabstop=2 shiftwidth=2 expandtab
