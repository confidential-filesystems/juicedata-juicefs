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
if [ -s ${CurrFsDir}/juicefs ]; then
  JuiceFS=${CurrFsDir}/juicefs
else
  JuiceFS=../../juicefs
fi

# encrypt key
echo "" && echo "" && echo ""
PriKeyPwd=123456
export JFS_RSA_PASSPHRASE=${PriKeyPwd}

#
MountPoint=/mnt/jfs_${FsId}

# info
echo "" && echo "" && echo ""
ps -auxf | grep -v grep | grep -i "juicefs mount"

# umount
echo "" && echo "" && echo ""
${JuiceFS} umount ${MountPoint}

echo "" && echo "" && echo ""
ps -auxf | grep -v grep | grep -i "juicefs mount"

#
echo "" && echo "" && echo ""
echo "umount fs (FsId=${FsId}) over."
echo "" && echo "" && echo ""
exit 0
#end
