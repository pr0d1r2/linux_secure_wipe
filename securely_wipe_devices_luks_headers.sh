#!/bin/bash

function securely_wipe_device_luks_header() {
  if [ ! -d /tmp/$1.luks.$2 ]; then
    dd if=/dev/urandom of=$1 bs=512 count=20480 || return $?
    mkdir -p /tmp/$1.luks.$2 || return $?
  fi
}

function securely_wipe_devices_luks_headers() {
  case $PASSES in
    '')
      PASSES=20
      ;;
  esac

  PASS=1
  while [ $PASS -le $PASSES ]
  do
    echo "Securely wiping LUKS header (pass $PASS of $PASSES) from: $@ ..."
    for DEVICE in $@
    do
      securely_wipe_device_luks_header $DEVICE $PASS &
    done
    wait
    PASS=`expr $PASS + 1`
    echo
  done
}

securely_wipe_devices_luks_headers $@
