#!/bin/bash

function echorun() {
  echo "$@"
  $@ || return $?
}

function until_success() {
  local until_success_ERR
  local until_success_SLEEP
  local until_success_RUN
  local until_success_ATTEMPT
  case $SLEEP in
    "")
      until_success_SLEEP=60
      ;;
    [0-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9])
      until_success_SLEEP=$SLEEP
      ;;
  esac
  case $ATTEMPTS in
    "")
      until_success_ATTEMPTS=10
      ;;
    [1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9])
      until_success_ATTEMPTS=$ATTEMPTS
      ;;
  esac
  until_success_ERR=1
  until_success_RUN=1
  until_success_ATTEMPT=1
  while [ $until_success_ERR -gt 0 ]; do
    echo "until_success: run #$until_success_RUN (`date`)"
    $@
    until_success_ERR=$?
    if [ $until_success_ERR -gt 0 ]; then
      sleep $until_success_SLEEP
      until_success_RUN=$(( $until_success_RUN + 1 ))
    fi
    if [ $until_success_ATTEMPTS -eq $until_success_ATTEMPT ]; then
      return 1
    fi
    until_success_ATTEMPT=$(( $until_success_ATTEMPT + 1 ))
  done
  echo "until_success: SUCCESS: run #$until_success_RUN (`date`)"
}

function random_hashing() {
  declare -a HASHING_METHODS=(sha1 sha256 sha512)
  local RAND=$[ $RANDOM % 3 ]
  echo -n ${HASHING_METHODS[$RAND]}
}

function random_key_size() {
  declare -a KEY_SIZES=(256 512)
  local RAND=$[ $RANDOM % 2 ]
  echo -n ${KEY_SIZES[$RAND]}
}

function random_key_offset() {
  declare -a KEY_OFFSETS=(0 1 2 3 4 5 6 7 8 9)
  local RAND=$[ $RANDOM % 10 ]
  echo -n ${KEY_OFFSETS[$RAND]}
}

function random_filling() {
  declare -a FILLING_METHODS=(shred)
  local RAND=$[ $RANDOM % 1 ]
  local DEVICE_SIZE=`blockdev --getsize64 $1`
  case `echo -n ${FILLING_METHODS[$RAND]}` in
    shred)
      echorun shred --verbose -n1 $1
      ;;
    shred_random) # disabled as it is slow
      echorun shred --verbose --random-source=/dev/urandom -n1 $1
      ;;
    badblocks) # disabled as causing segmentation faults on Ubuntu 16.04
      local BLOCK_COUNT=`expr $DEVICE_SIZE / 1024`
      echorun badblocks -c $BLOCK_COUNT -wsv $1
      ;;
    dd_zero) # disabled as shred is 4x faster
      local DD_BLOCKS=`expr $DEVICE_SIZE / 4096`
      echorun dd if=/dev/zero of=$1 iflag=nocache oflag=direct bs=4096 count=$DD_BLOCKS status=progress
      ;;
  esac
  return $?
}

function securely_wipe_device() {
  if [ ! -d /tmp/$1.wipe.$2 ]; then
    local CONTAINER_NAME=`basename $1`
    SLEEP=1 until_success cryptsetup open \
      --cipher=aes-xts-plain \
      --hash=`random_hashing` \
      --key-size=`random_key_size` \
      --offset=`random_key_offset` \
      --type plain \
      $1 \
      container-$CONTAINER_NAME \
      --key-file /dev/urandom || return $?
    random_filling /dev/mapper/container-$CONTAINER_NAME
    local FILLING_RESULT=$?
    until_success cryptsetup close container-$CONTAINER_NAME
    if [ $FILLING_RESULT -eq 0 ]; then
      mkdir -p /tmp/$1.wipe.$2 || return $?
    fi
    return $FILLING_RESULT
  fi
}

function securely_wipe_devices() {
  case $PASSES in
    '')
      local PASSES=5
      ;;
  esac

  local PASS=1
  while [ $PASS -le $PASSES ]
  do
    echo "Securely wiping space (pass $PASS of $PASSES) from: $@ ..."
    for DEVICE in $@
    do
      securely_wipe_device $DEVICE $PASS &
    done
    wait
    PASS=`expr $PASS + 1`
    echo
  done
}

securely_wipe_devices $@
