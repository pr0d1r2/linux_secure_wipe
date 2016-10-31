#!/bin/bash

declare -a DISKS=()

for P in $@
do
  case $P in
    -a | --all-disks)
      declare -a DISKS=`lsblk | grep "^sd" | cut -f 1 -d ' '`
      ;;
    sd[a-z])
      DISKS+=($P)
      ;;
    /dev/sd[a-z])
      DISKS+=(`basename $P`)
      ;;
  esac
done

function echorun() {
  echo "$@"
  $@ || return $?
}

for DISK in ${DISKS[@]}
do
  echorun smartctl -a /tmp/$DISK > /tmp/$DISK.smart
  if [ $? -eq 0 ]; then
    echorun mv /tmp/$DISK.smart /tmp/$DISK.smart.success
  else
    echorun mv /tmp/$DISK.smart /tmp/$DISK.smart.error
  fi
done
