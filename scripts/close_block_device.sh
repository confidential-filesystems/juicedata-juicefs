#!/bin/bash

set -x
set -o pipefail

if [ ! $# -eq 2 ]; then
  echo "Usage: $0 <mapper-name> <mount-point>"
  exit 1
fi

MAPPER_NAME=$1
MOUNT_POINT=$2

umount "${MOUNT_POINT}"
cryptsetup close "${MAPPER_NAME}"
exit 0
