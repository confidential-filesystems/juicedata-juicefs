#!/bin/bash

set -e

if [ ! $# -eq 4 ]; then
    echo "Usage: $0 <device> <mapper> <mount-point> <password-file|password-env>"
    exit 1
fi

DEVICE=$1
MAPPER_NAME=$2
MOUNT_POINT=$3
PASSWORD=$4
firstTime=0

if [ -f "$PASSWORD" ]; then
  DEVICE_PASSWORD=$(cat "$PASSWORD")
else
  DEVICE_PASSWORD=${!PASSWORD}
fi

if [ -z "${DEVICE_PASSWORD}" ]; then
  echo "no DEVICE_PASSWORD"
  exit 2
fi

if cryptsetup isLuks $DEVICE; then
    echo "Device $DEVICE is already LUKS formatted."
    echo -n ${DEVICE_PASSWORD} | cryptsetup luksOpen $DEVICE "$MAPPER_NAME" --disable-keyring -d /dev/stdin
else
    echo "Device $DEVICE is not LUKS formatted. Formatting now..."
    # format
    echo -n ${DEVICE_PASSWORD} | cryptsetup -q luksFormat --type luks2 --hash sha256 --pbkdf pbkdf2 --pbkdf-force-iterations 10000 $DEVICE -d /dev/stdin

    # create fs
    echo -n ${DEVICE_PASSWORD} | cryptsetup luksOpen $DEVICE "$MAPPER_NAME" --disable-keyring -d /dev/stdin
    mkfs.ext4 /dev/mapper/"$MAPPER_NAME"
    firstTime=1
fi

# resize if needed
if [ $firstTime -eq 0 ]; then
  set +e
  echo "Resize if needed"
  MAPPER=/dev/mapper/"$MAPPER_NAME"
  DEVICE_SIZE=$(blockdev --getsize64 "$MAPPER")
  if [ $? -ne 0 ]; then
      echo "Error: Failed to get device size for $MAPPER"
  else
      echo "Device size (bytes): $DEVICE_SIZE"
      FS_INFO=$(dumpe2fs -h "$MAPPER" 2>/dev/null)
      if [ $? -ne 0 ]; then
          echo "Error: Failed to get filesystem info for $MAPPER"
      else
          BLOCK_COUNT=$(echo "$FS_INFO" | grep 'Block count:' | awk '{print $3}')
          BLOCK_SIZE=$(echo "$FS_INFO" | grep 'Block size:' | awk '{print $3}')
          FILESYSTEM_SIZE=$((BLOCK_COUNT * BLOCK_SIZE))
          echo "Filesystem size (bytes): $FILESYSTEM_SIZE"
          if [ "$FILESYSTEM_SIZE" -lt "$DEVICE_SIZE" ]; then
              echo "Filesystem is smaller than the device. Resizing..."
              cryptsetup resize "$MAPPER"
              echo "cryptsetup resize result $?"
              timeout 600s e2fsck -f -y "$MAPPER"
              echo "e2fsck result $?"
              resize2fs "$MAPPER"
              if [ $? -eq 0 ]; then
                  echo "Resize successful."
               else
                  echo "Resize failed."
               fi
          else
             echo "No need to resize. Filesystem is already equal or larger than the device."
          fi
      fi
  fi
  set -e
fi

# check mount point
if [ ! -d "$MOUNT_POINT" ]; then
  echo "Mount point '$MOUNT_POINT' does not exist. Creating it now..."
  mkdir -p "$MOUNT_POINT"
else
  echo "Mount point '$MOUNT_POINT' already exists."
fi

# mount 
mount /dev/mapper/"$MAPPER_NAME" "$MOUNT_POINT"

# remove lost+found directory only if this was a new formatting operation (i.e., not on every script run)
#if [ $firstTime -eq 1 ] && [ ! "$(ls "${MOUNT_POINT}" | grep 'lost\+found')" ]; then
#  echo "remove lost+found for the first time"
#  rm -rf "${MOUNT_POINT}/lost+found"
#fi

echo "" && echo "" && echo ""
echo "Done. Device '$DEVICE' has been opened and mounted to '$MOUNT_POINT'."
exit 0