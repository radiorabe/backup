#!/bin/bash
# backup files from VMs
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

get_migrated_vms(){
  cat /home/backup/migrated_vms
}

main(){
  local errs_all=0
  log -i "Rsync backup of VMs starting"
  mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bkp
  for vm in $(get_migrated_vms) $(get_vms); do
    log -i "Starting backup of $vm"
    local vm_fqdn="$vm.***REMOVED***"
    if [[ $vm == ***REMOVED*** ]]; then
      # ***REMOVED*** only has a dmz address
      vm_fqdn="${vm}.dmz.int.rabe.ch"
    fi
    local custom_rsync_opts=""
    if [[ $vm == ***REMOVED*** ]]; then
      # ***REMOVED*** does not support extended attributes
      custom_rsync_opts="$custom_rsync_opts --no-xattrs"
    fi
    local start; start=$(date +%s)
    local errs=0
    ssh-keyscan "$vm_fqdn" >> ~/.ssh/known_hosts 2>/dev/null
    for dir in "${BACKUP_DIRS[@]}"; do
      if ! do_rsync "$vm_fqdn:$dir" "$BACKUP_DST_DIR/$vm" "$custom_rsync_opts"; then
        ((errs++))
      fi
    done
    log -i "Starting backup of custom dirs for $vm_fqdn"
    if ! backup_custom_dirs "$vm_fqdn" "$BACKUP_DST_DIR/$vm"; then
      ((errs++))
    fi
    if [[ $errs -eq 0 ]]; then
      log -i "Backup of $vm_fqdn successful!"
      if [[ $vm == ***REMOVED*** ]]; then
        log -i "Not sending Zabbix status for $vm"
      else
        backup_success "$vm_fqdn" "$start"
      fi
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
