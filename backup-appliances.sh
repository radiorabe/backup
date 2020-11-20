#!/bin/bash
# backup files from appliances
# TODO: DRY
set -u
. "$(dirname "$0")/backup-util.sh"

GWS=("***REMOVED***" "***REMOVED***")
GW_DIRS=("/home/backup/" "***REMOVED***/")
STREAM="***REMOVED***"
STREAM_DIR="***REMOVED****"

main(){
  log -i "Appliance backup starting"
  mv ~/.ssh/known_hosts ~/.ssh/known_hosts.bkp
  local errs_all=0

  # backup gateways
  for gw in "${GWS[@]}"; do
    local start; start=$(date +%s)
    local errs=0
    ssh-keyscan "$gw" >> ~/.ssh/known_hosts 2> /dev/null
    for dir in "${GW_DIRS[@]}"; do
      set -x
      scp -rp -i "$SSH_KEY" "$SSH_USER@$gw:$dir" "$BACKUP_DST_DIR/$gw"
      set +x
      ret=$?
      if [[ $ret -eq 0 ]]; then
        log -s "Backup of $gw:$dir to $BACKUP_DST_DIR/$gw successful!"
      else
        log -e "Unknown error ($ret) occured when trying to backup $gw:$dir."
        ((errs++))
      fi
    done
    if [[ $errs -eq 0 ]]; then
      if ! backup_success "$gw" "$start"; then
        log -e "Could not send status for $gw to Zabbix"
      fi
    else
      ((errs_vm_all++))
      log -w "$gw had problems during the backup job"
    fi
  done

  # backup stream
  ssh-keyscan "$STREAM" >> ~/.ssh/known_hosts 2> /dev/null
  set -x
  scp -rp -i "$SSH_KEY" "$SSH_USER@$STREAM:$STREAM_DIR" "$BACKUP_DST_DIR/$STREAM"
  ret=$?
  set +x
  if [[ $ret -eq 0 ]]; then
    log -s "Backup of $STREAM:$STREAM_DIR to $BACKUP_DST_DIR/$STREAM successful!"
    if ! backup_success "$gw" "$start"; then
      log -e "Could not send status for $gw to Zabbix"
    fi
  else
    log -e "Unknown error ($ret) occured when trying to backup $gw:$dir."
    ((errs_all++))
  fi

  mv ~/.ssh/known_hosts.bkp ~/.ssh/known_hosts
  log -i "Script finished; $errs_all appliances had problems during the backup job."
  if [[ $errs_all -gt 0 ]]; then
    exit 1
  fi
}
main
# vim: tabstop=2 shiftwidth=2 expandtab
