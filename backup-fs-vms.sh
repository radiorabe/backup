#!/bin/bash
# backup files from VMs
. "$(dirname "$0")/backup-util.sh"
set +o xtrace # do not log sensitive data
. "$CONF_DIR/fs-vms.sh"
set -o xtrace

BACKUP_DIRS=(
  "/etc" "/home" "/root" "/usr/local" "/var/log" "/var/local" "/var/spool" "/var/backup"
  "/var/backups"
)

# get access token from oauth token endpoint required for API usage
get_access_token(){
  url="$1"
  user="$2"
  pass="$3"
  curl --silent --insecure --header "Accept: application/json" \
    --data-urlencode "grant_type=password" \
    --data-urlencode "scope=ovirt-app-api" \
    --data-urlencode "username=$user" \
    --data-urlencode "password=$pass" \
    "$url/sso/oauth/token" | \
    jq -r ".access_token"
}

# fetch list of vms from ovirt
# usage: vms=$(get_vms)
get_vms(){
  set +o xtrace # do not log sensitive data
  for i in "${!OVIRT_URLS[@]}"; do
    url=${OVIRT_URLS[$i]}
    user=${OVIRT_USERS[$i]}
    pass=${OVIRT_PASSWORDS[$i]}
    access_token="$(get_access_token "$url" "$user" "$pass")"
    # filter result by only running VMs
    # https://ovirt.github.io/ovirt-engine-api-model/master/#services/vms/methods/list
    curl --silent --insecure --header "Accept: application/json" \
      --header "Authorization: Bearer $access_token" \
      "$url/api/vms?search=status=up" | \
      jq --raw-output '.vm[].name | select(. | test("^vm-[0-9]{4}"))'
  done
  set -o xtrace
}

main(){
  local errs_all=0
  log -i "Rsync backup of VMs starting"
  mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bkp
  for vm in $(get_vms); do
    log -i "Starting backup of $vm"
    local vm_fqdn="$vm.$VM_SUFFIX"
    if [[ ${SPECIAL_FQDNS[@]} =~ $vm ]]; then
      for fqdn in "${SPECIAL_FQDNS[@]}"; do
        if [[ $fqdn =~ $vm ]]; then
          vm_fqdn=$fqdn
          break
        fi
      done
    fi
    local custom_rsync_opts=""
    local start; start=$(date +%s)
    local errs=0
    ssh-keyscan "$vm_fqdn" >> ~/.ssh/known_hosts 2>/dev/null
    for dir in "${BACKUP_DIRS[@]}"; do
      if ! do_rsync "$vm_fqdn:$dir" "$BACKUP_DST_DIR/$vm" "$custom_rsync_opts"; then
        ((errs++))
      fi
    done
    log -i "Starting backup of custom dirs for $vm_fqdn"
    if ! backup_custom_dirs "$vm_fqdn" "$BACKUP_DST_DIR/$vm" "$custom_rsync_opts"; then
      ((errs++))
    fi
    if [[ $errs -eq 0 ]]; then
      log -i "Backup of $vm_fqdn successful!"
      backup_success "$vm_fqdn" "$start"
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
