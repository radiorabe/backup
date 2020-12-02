#!/bin/bash
# backup user shares
. "$(dirname "$0")/backup-util.sh"

BACKUP_SRC_HOST="vm-0018.vm-admin.int.rabe.ch"
BACKUP_SRC_DIRS=(
    "/vservers/hq.rabe.ch/samba-01/home/"
    "/vservers/hq.rabe.ch/samba-01/music/"
    "/vservers/hq.rabe.ch/samba-01/shares/"
    "/vservers/hq.rabe.ch/samba-01/transfer/"
)
BACKUP_DST_DIRS=(
    "/srv/backup/homes"
    "/srv/backup/music"
    "/srv/backup/shares"
    "/srv/backup/transfer"
)

main(){
  log -i "Rsync backup of userdata starting"
  mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bkp
  ssh-keyscan "$BACKUP_SRC_HOST" >> ~/.ssh/known_hosts 2>/dev/null
  local errs=0
  local i=0
  if [[ ! -d ${BACKUP_DST_DIRS[i]} ]]; then
    log -e "Destination ${BACKUP_DST_DIRS[i]} is not a directory"
    ((errs++))
  fi
  until [[ -z ${BACKUP_SRC_DIRS[i]} ]]; do
    if ! do_rsync "$BACKUP_SRC_HOST:${BACKUP_SRC_DIRS[i]}" "${BACKUP_DST_DIRS[i]}"; then
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
