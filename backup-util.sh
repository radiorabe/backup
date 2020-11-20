#!/bin/bash
#
# utility functions for backup scripts

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
# vim: tabstop=2 shiftwidth=2 expandtab
