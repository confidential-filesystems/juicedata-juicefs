#!/bin/bash

set -e

if [ ! $# -eq 3 ]; then
    echo "Usage: $0 <device> <mapper> <mount-point>"
    exit 1
fi

DEVICE=$1
MAPPER_NAME=$2
MOUNT_POINT=$3
firstTime=0

echo DEVICE_PASSWORD=${DEVICE_PASSWORD}
if [ -z "${DEVICE_PASSWORD}" ]; then
  echo "DEVICE_PASSWORD=${DEVICE_PASSWORD}"
  exit 2
fi

if cryptsetup isLuks $DEVICE; then
    echo "Device $DEVICE is already LUKS formatted."
    echo ${DEVICE_PASSWORD} | cryptsetup luksOpen $DEVICE "$MAPPER_NAME" --disable-keyring -d /dev/stdin
else
    echo "Device $DEVICE is not LUKS formatted. Formatting now..."
    # format
    echo ${DEVICE_PASSWORD} | cryptsetup -q luksFormat --type luks2 --hash sha256 --pbkdf pbkdf2 --pbkdf-force-iterations 10000 $DEVICE -d /dev/stdin

    # create fs
    echo ${DEVICE_PASSWORD} | cryptsetup luksOpen $DEVICE "$MAPPER_NAME" --disable-keyring -d /dev/stdin
    mkfs.ext4 /dev/mapper/"$MAPPER_NAME"
    firstTime=1
fi

# resize if needed
if [ $firstTime -eq 0 ]; then
  echo "resize if needed"
  cryptsetup resize /dev/mapper/"$MAPPER_NAME"
  e2fsck -f -y /dev/mapper/"$MAPPER_NAME"
  resize2fs /dev/mapper/"$MAPPER_NAME"
  echo "resize done"
fi

# check mount point
if [ ! -d "$MOUNT_POINT" ]; then
  mkdir -p "$MOUNT_POINT"
fi

# mount 
mount /dev/mapper/"$MAPPER_NAME" "$MOUNT_POINT"

# remove lost+found directory only if this was a new formatting operation (i.e., not on every script run)
if [ $firstTime -eq 0 ] && [ ! "$(ls "${MOUNT_POINT}" | grep 'lost\+found')" ]; then
  echo "remove lost+found for the first time"
  rm -rf "${MOUNT_POINT}/lost+found"
fi

echo "" && echo "" && echo ""
echo "Done. Device '$DEVICE' has been opened and mounted to '$MOUNT_POINT'."
exit 0