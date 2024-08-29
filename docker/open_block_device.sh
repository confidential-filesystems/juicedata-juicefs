#!/bin/bash

set -eux
set -o pipefail

if [ ! $# -eq 4 ]; then
  echo "Usage: $0 <device> <mapper> <mount-point> <password-file|password-env>"
  exit 1
fi

DEVICE=$1
MAPPER_NAME=$2
MOUNT_POINT=$3
PASSWORD=$4
DO_FORMAT=0

if [ -f "${PASSWORD}" ]; then
  DEVICE_PASSWORD=$(cat "${PASSWORD}")
else
  DEVICE_PASSWORD=${!PASSWORD}
fi

if [ -z "${DEVICE_PASSWORD}" ]; then
  echo "ERROR: device password is required"
  exit 2
fi

# initialize, open and format
if cryptsetup isLuks "${DEVICE}"; then
  echo "INFO: device ${DEVICE} is already initialized as LUKS, open it directly"
  echo -n "${DEVICE_PASSWORD}" | cryptsetup luksOpen "${DEVICE}" "${MAPPER_NAME}" --disable-keyring -d /dev/stdin
  echo "INFO: LUKS opened"
else
  echo "INFO:device $DEVICE is not initialized as LUSK yet, initialize, open and format it to EXT4"
  echo -n "${DEVICE_PASSWORD}" | cryptsetup -q luksFormat --type luks2 --hash sha256 --pbkdf pbkdf2 --pbkdf-force-iterations 10000 "${DEVICE}" -d /dev/stdin
  echo "INFO: LUKS initialized"
  echo -n "${DEVICE_PASSWORD}" | cryptsetup luksOpen "${DEVICE}" "${MAPPER_NAME}" --disable-keyring -d /dev/stdin
  echo "INFO: LUKS opened"
  mkfs.ext4 "/dev/mapper/${MAPPER_NAME}"
  echo "INFO: EXT4 formatted"
  DO_FORMAT=1
fi

# resize if needed
if [ ${DO_FORMAT} -eq 0 ]; then
  echo "INFO: resize ${DEVICE} if needed"

  MAPPER_DEVICE="/dev/mapper/${MAPPER_NAME}"
  DEVICE_SIZE=$(blockdev --getsize64 "${MAPPER_DEVICE}")
  echo "INFO: device size (bytes): ${DEVICE_SIZE}"

  FS_INFO=$(dumpe2fs -h "${MAPPER_DEVICE}" 2>/dev/null)
  BLOCK_COUNT=$(echo "${FS_INFO}" | grep 'Block count:' | awk '{print $3}')
  BLOCK_SIZE=$(echo "${FS_INFO}" | grep 'Block size:' | awk '{print $3}')
  FILESYSTEM_SIZE=$((BLOCK_COUNT * BLOCK_SIZE))
  echo "INFO: filesystem size (bytes): ${FILESYSTEM_SIZE}"

  if [ "${FILESYSTEM_SIZE}" -lt "${DEVICE_SIZE}" ]; then
    echo "INFO: resize is needed"
    cryptsetup resize "${MAPPER_DEVICE}"
    echo "INFO: LUKS resized"

    set -e
    time 600 e2fsck -f -y "${MAPPER_DEVICE}"
    echo "INFO: filesystem checked"
    set +e

    resize2fs "$MAPPER_DEVICE"
    echo "INFO: filesystem resized"
  fi
fi

# check mount point
if [ ! -d "${MOUNT_POINT}" ]; then
  echo "INFO: mount point ${MOUNT_POINT} does not exist, creating it now"
  mkdir -p "$MOUNT_POINT"
fi

# mount
mount "/dev/mapper/${MAPPER_NAME}" "${MOUNT_POINT}"

# remove lost+found directory
# if [ ${DO_FORMAT} -eq 1 ] && [ "$(find "${MOUNT_POINT}" -maxdepth 1 -type d -name "lost+found" | grep -c "lost+found")" != "0" ]; then
#   rm -rf "${MOUNT_POINT}/lost+found"
# fi

echo "INFO: ALL DONE. Device ${DEVICE} has been opened and mounted to ${MOUNT_POINT}"
exit 0
