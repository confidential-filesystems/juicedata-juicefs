#!/bin/bash

CurrDir=$(cd "$(dirname "$0")"; pwd)

FsId=1
if [ $1 ]; then
  FsId=$1
fi
echo FsId=${FsId}

CurrFsDir=myjfs_${FsId}

# bin
#rm -f ${CurrFsDir}/juicefs
#cp ../../juicefs ${CurrFsDir}/
#JuiceFS=${CurrFsDir}/juicefs
JuiceFS=../../juicefs

# encrypt key
echo "" && echo "" && echo ""
PriKeyPwd=123456
#export JFS_RSA_PASSPHRASE=${PriKeyPwd}

#
MountPoint=/mnt/jfs_${FsId}

# info
echo "" && echo "" && echo ""
ps -auxf | grep -v grep | grep -i "juicefs mount"

# read / write test
echo "" && echo "" && echo ""
echo "haha111" > ${MountPoint}/file1

echo "" && echo "" && echo ""
cat ${MountPoint}/file1

#
echo "" && echo "" && echo ""
echo "test1 fs (FsId=${FsId}) over."
echo "" && echo "" && echo ""
exit 0
#end
