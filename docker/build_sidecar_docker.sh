#!/bin/bash

set -e
SERVICE_NAME=cfs-sidecar
VERSION=v0.1.0
HUB=hub.confidentialfilesystems.com:4443

git pull

time=$(date "+%F %T")
echo "build juicefs"
cd ..
REVISION=$(git rev-parse --short HEAD 2>/dev/null)
REVISIONDATE=$(git log -1 --pretty=format:'%cd' --date short 2>/dev/null)
PKG=github.com/juicedata/juicefs/pkg/version
LDFLAGS="-s -w -X ${PKG}.revision=${REVISION} -X ${PKG}.revisionDate=${REVISIONDATE}"

GOOS=linux GOARCH=amd64 CGO_LDFLAGS="-static" go build -tags nogateway,nowebdav,nocos,nobos,nohdfs,noibmcos,noobs,nooss,noqingstor,noscs,nosftp,noswift,noupyun,noazure,nogs,noufile,nob2,nosqlite,nomysql,nopg,notikv,nobadger,noetcd \
-ldflags="${LDFLAGS}" -o juicefs .

echo "build webdav"
cd ./docker
git clone https://github.com/confidential-filesystems/filesystem-webdav.git filesystem-webdav-project
pushd filesystem-webdav-project
REVISION=$(git rev-parse --short HEAD 2>/dev/null)
LDFLAGS="-X 'github.com/confidential-filesystems/filesystem-webdav/cmd.version=${REVISION}'"
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 CGO_LDFLAGS="-static" go build -ldflags "${LDFLAGS}" -o filesystem-webdav
popd

mv ../juicefs .
mv ./filesystem-webdav-project/filesystem-webdav .
cp ./filesystem-webdav-project/examples/config-example.yaml webdav-config.yaml

docker build -f ./sidecar.Dockerfile -t ${HUB}/cc/${SERVICE_NAME}:${VERSION} .
docker push ${HUB}/cc/${SERVICE_NAME}:${VERSION}

rm -rf filesystem-webdav-project
rm juicefs
rm filesystem-webdav
rm webdav-config.yaml

echo "build time: $(date)"
