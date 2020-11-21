#!/bin/bash
# backup files from VMs
set -u
. "$(dirname "$0")/backup-util.sh"

BACKUP_DIRS=(
  "/etc" "/home" "/root" "/usr/local" "/var/log" "/var/local" "/var/spool" "/var/backup"
  "/var/backups"
)

# fetch list of vms from ovirt
# usage: vms=$(get_vms)
get_vms(){
  local ovirt_url="https://***REMOVED***/ovirt-engine/api"
  local ovirt_user="***REMOVED***"
  local ovirt_password; ovirt_password=$(cat /home/backup/.ovirt_password)

  # filter result by only running VMs
  # http://ovirt.github.io/ovirt-engine-api-model/master/#services/vms/methods/list
  curl --silent --insecure --header "Accept: application/xml" --user "$ovirt_user:$ovirt_password" \
      "$ovirt_url/vms?search=status%3Dup" | \
      sed -n 's/<name>\(vm-.\{4\}\)<\/name>/\1/p' | tr -d '\n'
}

main(){
  local errs_all=0
  log -i "Rsync backup of VMs starting"
  mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bkp
  for vm in $(get_vms); do
    if [[ $vm == "***REMOVED***" ]]; then
      log -i "Skipping backup of ***REMOVED*** as it is handled in backup-physical-servers.sh"
      continue
    fi
    local vm_fqdn="$vm.***REMOVED***"
    local start; start=$(date +%s)
    local errs=0
    ssh-keyscan "$vm_fqdn" >> ~/.ssh/known_hosts 2>/dev/null
    for dir in "${BACKUP_DIRS[@]}"; do
      if ! do_rsync "$vm_fqdn:$dir" "$BACKUP_DST_DIR/$vm"; then
        ((errs++))
      fi
    done
    log -i "Starting backup of custom dirs for $vm_fqdn. Current errors: $errs"
    if ! backup_custom_dirs "$vm_fqdn" "$BACKUP_DST_DIR/$vm"; then
      ((errs++))
    fi
    log -i "Ended backup of custom dirs for $vm_fqdn. Current errors: $errs"
    if [[ $errs -eq 0 ]]; then
      log -i "Backup of $vm_fqdn successful!"
      set -x
      backup_success "$vm_fqdn" "$start"
      set +x
    else
      log -e "$vm had problems during the backup job"
      ((errs_all++))
    fi
  done
  mv ~/.ssh/known_hosts.bkp ~/.ssh/known_hosts
  exit "$errs_all"
}
main
# vim: tabstop=2 shiftwidth=2 expandtab
