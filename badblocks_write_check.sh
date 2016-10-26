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

for DISK in ${DISKS[@]}
do
  badblocks -wsv -o /tmp/$DISK.badblocks /dev/$DISK &
done
wait
