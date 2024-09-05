#!/bin/bash
# backup files from physical servers
. "$(dirname "$0")/backup-util.sh"
. "$CONF_DIR/physical_servers.sh"

BACKUP_DIRS=(
  "/etc" "/home" "/root" "/usr/local" "/var/log" "/var/local" "/var/spool" "/var/backup"
  "/var/backups"
)

main(){
  local errs_all=0
  log -i "Rsync backup of physical hosts starting"
  mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bkp
  for server in "${SERVERS[@]}"; do
    log -i "Starting backup of $server"
    local start; start=$(date +%s)
    local errs=0
    ssh-keyscan "$server" >> ~/.ssh/known_hosts 2>/dev/null
    for dir in "${BACKUP_DIRS[@]}"; do
      if ! do_rsync "$server:$dir" "$BACKUP_DST_DIR/$server"; then
        ((errs++))
      fi
    done
    log -i "Starting backup of custom dirs for $server"
    if ! backup_custom_dirs "$server" "$BACKUP_DST_DIR/$server"; then
      ((errs++))
    fi
    if [[ $errs -eq 0 ]]; then
      log -i "Backup of $server successful!"
      backup_success "$server" "$start"
    else
      log -e "$server had problems during the backup job"
      ((errs_all++))
    fi
  done
  mv ~/.ssh/known_hosts.bkp ~/.ssh/known_hosts
  exit "$errs_all"
}
main
# vim: tabstop=2 shiftwidth=2 expandtab
