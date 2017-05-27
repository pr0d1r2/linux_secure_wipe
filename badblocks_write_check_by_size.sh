#!/bin/bash

case $1 in
  "")
    echo
    echo "You need to give size of disk in GiB as first parameter!"
    echo
    echo "For example for 1TB disks:"
    echo "badblocks_write_check_by_size 931.5"
    exit 1
    ;;
esac
SIZE=$1

for DISK in `fdisk -l /dev/sd? | \
             grep "Disk /" | \
             grep "$SIZE GiB" | \
             cut -f 2 -d ' ' | \
             cut -f 3 -d / | \
             cut -f 1 -d :`
do
  badblocks -wsv -o /tmp/$DISK.badblocks /dev/$DISK &
done
wait
