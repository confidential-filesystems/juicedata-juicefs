#!/bin/bash

CurrDir=$(cd "$(dirname "$0")"; pwd)

FsId=1
if [ $1 ]; then
  FsId=$1
fi
echo FsId=${FsId}

CurrFsDir=myjfs_${FsId}
mkdir -p ${CurrFsDir}

# bin
rm -f ${CurrFsDir}/juicefs
cp ../../juicefs ${CurrFsDir}/
JuiceFS=${CurrFsDir}/juicefs

# postgres for metadata store
echo "" && echo "" && echo ""
postgresHost=10.12.32.134
postgresPort=5432
postgresUsr=cfs
postgresPwd=password
postgresURL=postgres://${postgresUsr}:${postgresPwd}@${postgresHost}:${postgresPort}
postgresDBName=juicefs
postgresDB=${postgresDBName}?search_path=jfs_${FsId}

# encrypt key
echo "" && echo "" && echo ""
PriKey=my-priv-key.pem
PriKeyPwd=123456
if [ -s ./${PriKey} ]; then
  printf "\\r ${PriKey} is exist .\\n"
else
  printf "\\r ${PriKey} is not exist -> ERROR\\n"
  exit 1
fi
export JFS_RSA_PASSPHRASE=${PriKeyPwd}

#
MountPoint=/mnt/jfs_${FsId}

# info
echo "" && echo "" && echo ""
ps -auxf | grep -v grep | grep -i "juicefs mount"

# mount
echo "" && echo "" && echo ""
${JuiceFS} mount -d \
  --log /var/log/juicefs_${FsId}.log \
  --encrypt-root-key ./${PriKey} \
  ${postgresURL}/${postgresDB} \
  ${MountPoint}

# --subdir value          mount a sub-directory as root

echo "" && echo "" && echo ""
ps -auxf | grep -v grep | grep -i "juicefs mount"

#
echo "" && echo "" && echo ""
echo "mount fs (FsId=${FsId}) over."
echo "" && echo "" && echo ""
exit 0
#end
