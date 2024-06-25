#!/bin/bash

CurrDir=$(cd "$(dirname "$0")"; pwd)

echo "" && echo "" && echo ""
Op=none
if [ $1 ]; then
  Op=$1
  shift
fi
echo Op=${Op}

#
echo "" && echo "" && echo ""
# apt-get update
# apt-get install -y musl-tools upx-ucl
#rm -f ./juicefs
#go build
#STATIC=1 make
if [ -s ./juicefs ]; then
	echo "compile juicefs succ ."
else
    echo "ERROR: compile juicefs fail !"
    exit 1;
fi

#
echo "" && echo "" && echo ""
SideCarImage=juicedata-juicefs-sidecar:v1.1.2-filesystem-1
docker rmi -f ${SideCarImage}
docker build -f Dockerfile.sidecar -t ${SideCarImage} .

docker rmi -f hub.confidentialfilesystems.com:4443/cc/${SideCarImage}
docker tag ${SideCarImage} hub.confidentialfilesystems.com:4443/cc/${SideCarImage}
docker push hub.confidentialfilesystems.com:4443/cc/${SideCarImage}

echo "" && echo "" && echo ""
echo Op=${Op}
if [ ${Op} = "run-docker" ]; then
  SideCarContainer=juicedata-juicefs-sidecar-1
  docker rm -f ${SideCarContainer}

  docker run -itd --privileged \
    --rm --entrypoint=bash \
    --name=${SideCarContainer} \
    --restart=always \
    -e "DEVICE_PASSWORD=123456" \
    ${SideCarImage} \
    /bin/bash

  docker ps -a | grep -i ${SideCarContainer}

  docker exec -it ${SideCarContainer} bash
fi

#
echo "" && echo "" && echo ""
exit 0
#end.
