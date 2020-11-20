#!/bin/bash
#
# utility functions for backup scripts

# set environment variables
set_env(){
  export SSH_USER="backup"
  export SSH_KEY="/home/backup/.ssh/id_rsa"
  export BACKUP_DST_DIR="/srv/backup/remote-backup"
  export ZABBIX_CONFIG="/etc/zabbix/zabbix_agentd.conf"
  export ZABBIX_KEY="rabe.rabe-backup.run.success[]"
}

backup_success(){
  if [[ $# -ne 2 ]]; then
    log -e "Incorrect number of parameters for ${FUNCNAME[0]}"
  fi
  local hostname; hostname="$1"
  local start; start="$2"
  local ts; ts=$(date +%s)
  local duration=$((ts - start))
  local ret=0
  # send timestamp of last successful backup
  zabbix_sender --config "$ZABBIX_CONFIG" --host "$hostname" \
    --key "$ZABBIX_KEY" --value "$ts" || ret=$?
  # send duration of last successful backup
  zabbix_sender --config "$ZABBIX_CONFIG" --host "$hostname" \
    --key "$ZABBIX_KEY" --value "$duration" || ret=$?
  return $ret
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

set_env

# vim: tabstop=2 shiftwidth=2 expandtab
