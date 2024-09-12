#!/bin/bash

set -e
SERVICE_NAME=cfs-sidecar
HUB=hub.confidentialfilesystems.com:30443
VERSION=${1:-v0.1.4}
SSH_KEY=${2:-$HOME/.ssh/id_rsa}

docker build --ssh default=${SSH_KEY} -f ./filesystem-sidecar.dockerfile -t ${HUB}/cc/${SERVICE_NAME}:${VERSION} --build-arg WEBDAV_TAG=main .
docker push ${HUB}/cc/${SERVICE_NAME}:${VERSION}

echo "build time: $(date)"
