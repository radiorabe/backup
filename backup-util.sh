#!/bin/bash
#
# utility functions for backup scripts

# set environment variables
set_env(){
  export CONF_DIR="/etc/rabe-backup"
  export REMOTE_INCLUDE="/etc/rabe-backup.include"
  export REMOTE_EXCLUDE="/etc/rabe-backup.exclude"
  export RSYNC_PATH="sudo /bin/rsync"
  export SSH_KEY="/home/backup/.ssh/id_rsa"
  export SSH_USER="backup"
  export RSH_CMD="ssh -i $SSH_KEY -l $SSH_USER"
  export BACKUP_DST_DIR="/srv/backup/remote-backup"
  export ZABBIX_CONFIG="/etc/zabbix/zabbix_agentd.conf"
}

# log with a configurable prefix
# usage: log -n "test 123"
log(){
  local prefix
  case $1 in
    -e) prefix="Error:   ";;
    -i) prefix="Info:    ";;
    -n) prefix="Notice:  ";;
    -s) prefix="Success: ";;
    -w) prefix="Warning: ";;
    -d) prefix="Debug:   ";;
  esac
  if [[ -n $prefix ]]; then
    shift
  else
    prefix="         "
  fi
  echo "$prefix $0 $*"
}

# get content of a remote file
# usage: cat_remote_file vm-xyz.domain.net /etc/hosts
cat_remote_file(){
  local hostname=$1
  local file=$2
  $RSH_CMD "$hostname" "cat $file"
}

# send successful backup run and timestamp to Zabbix
# usage: backup_success hostname unix_ts_start
backup_success(){
  local hostname; hostname="$1"
  local start; start="$2"
  local ts; ts=$(date +%s)
  local duration=$((ts - start))
  local ret=0
  local zabbix_hostname;
  zabbix_hostname="$(cat_remote_file "$hostname" "/etc/zabbix/zabbix_agentd.conf" | \
    grep "^Hostname=.*$" | awk -F "=" '{print $2}')"
  if [[ -z $zabbix_hostname ]]; then
    zabbix_hostname=$hostname
  fi
  # send timestamp of last successful backup
  zabbix_sender --config "$ZABBIX_CONFIG" --host "$zabbix_hostname" \
    --key "rabe.rabe-backup.run.success[]" --value "$ts" || ret=$?
  # send duration of last successful backup
  zabbix_sender --config "$ZABBIX_CONFIG" --host "$zabbix_hostname" \
    --key "rabe.rabe-backup.run.duration[]" --value "$duration" || ret=$?
  if [[ $ret -ne 0 ]]; then
    log -e "Could not send status for $zabbix_hostname to Zabbix"
  fi
}

# handle the exit code of rsync
# usage: rsync a b; handle_rsync_ret $? a b
handle_rsync_ret(){
  local ret=$1
  local src=$2
  local dst=$3

  case $ret in
    0)
      log -s "Sync of $src to $dst successful!";;
    12)
      log -e "Permission denied on ${src}."
      ret=0;;
    23)
      log -i "$src does not exist"
      ret=0;;
    255)
      log -e "Host $src is not online or could not be resolved.";;
    *)
      log -e "Unknown error ($ret) occured when trying to rsync $src to $dst.";;
  esac
}

# rsync wrapper
# usage: do_rsync a b
do_rsync(){
  local src; src=$1
  local dst; dst=$2
  local custom_rsync_opts; custom_rsync_opts=${3-""}
  log -i "Starting rsync from $src to $dst"
  # shellcheck disable=SC2086
  rsync --rsync-path="$RSYNC_PATH" --rsh="$RSH_CMD" --verbose --archive --recursive --acls \
    --devices --specials --delete --numeric-ids --timeout=120 --stats --human-readable --progress \
    --inplace --one-file-system --relative $custom_rsync_opts "$src" "$dst" 2>/dev/null
  handle_rsync_ret $? "$src" "$dst"
  return $?
}

# backup directories specified by the remote system
# usage: backup_custom_dirs vm-xyz.domain.net
backup_custom_dirs(){
  local hostname=$1
  local dst=$2
  local errs=0
  # fetch include and exclude files
  local includes; includes=$(cat_remote_file "$hostname" "$REMOTE_INCLUDE")
  local excludes; excludes=$(cat_remote_file "$hostname" "$REMOTE_EXCLUDE")
  local exclude_opts=""
  for exclude in $excludes; do
    exclude_opts="$exclude_opts --exclude $exclude"
  done
  for include in $includes; do
    if ! do_rsync "$hostname:$include" "$dst" "$exclude_opts"; then
      ((errs++))
    fi
  done
  return "$errs"
}

set -u
set -o xtrace
set_env
# vim: tabstop=2 shiftwidth=2 expandtab
