#!/bin/bash

if [ ! $# -eq 2 ]; then
    echo "Usage: $0 <mapper> <mount-point>"
    exit 1
fi

MAPPER_NAME=$1
MOUNT_POINT=$2
umount "$MOUNT_POINT"
if [ $? -eq 0 ]; then
  echo "$MOUNT_POINT has been umounted"
else
  echo "fail to umount $MOUNT_POINT" 
fi

cryptsetup close "$MAPPER_NAME"
if [ $? -eq 0 ]; then
  echo "/dev/mapper/$MAPPER_NAME has been closed"
else
  echo "fail to close /dev/mapper/$MAPPER_NAME" 
fi

echo "" && echo "" && echo ""
exit 0
