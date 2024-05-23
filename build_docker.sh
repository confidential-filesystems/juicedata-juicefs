#!/bin/bash

CurrDir=$(cd "$(dirname "$0")"; pwd)

# hub.confidentialfilesystems.com/cc/juicefs:cfs-1.1.2
REPO_URL=hub.confidentialfilesystems.com
REPO_USR=${RepoUsr} # export RepoUsr=xxx
REPO_PWD=${RepoPwd} # export RepoPwd=yyy
IMG_DIR=cc

IMG_NAME=juicefs
IMG_VER=cfs-1.1.2

#
echo "" && echo "" && echo ""
echo "1: docker rmi -f ${IMG_NAME}:${IMG_VER}"
docker rmi -f ${IMG_NAME}:${IMG_VER}

#
echo "" && echo "" && echo ""
# apt-get update
# apt-get install -y musl-tools upx-ucl
rm -f ./juicefs
#go build
STATIC=1 make
if [ -s ./juicefs ]; then
	echo "compile juicefs succ ."
else
    echo "ERROR: compile juicefs fail !"
    exit 1;
fi

#
echo "" && echo "" && echo ""
echo "2: docker build -f Dockerfile -t ${IMG_NAME}:${IMG_VER} ."
docker build \
    -f Dockerfile -t ${IMG_NAME}:${IMG_VER} .

docker images | grep -i ${IMG_NAME}

docker rmi -f ${REPO_URL}/${IMG_DIR}/${IMG_NAME}:${IMG_VER}
docker tag ${IMG_NAME}:${IMG_VER} ${REPO_URL}/${IMG_DIR}/${IMG_NAME}:${IMG_VER}

echo "" && echo "" && echo ""
echo "3: docker push ${REPO_URL}/${IMG_DIR}/${IMG_NAME}:${IMG_VER}"
docker login -u="${REPO_USR}" -p="${REPO_PWD}" ${REPO_URL}
docker push ${REPO_URL}/${IMG_DIR}/${IMG_NAME}:${IMG_VER}

#
echo "" && echo "" && echo ""
exit 0
#end.
