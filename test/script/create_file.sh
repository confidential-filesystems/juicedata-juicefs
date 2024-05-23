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

echo q | psql --command "CREATE DATABASE ${postgresDBName}" "host=${postgresHost} hostaddr=${postgresHost} port=${postgresPort} user=${postgresUsr} password=${postgresPwd}"
echo q | psql --command "\l" "host=${postgresHost} hostaddr=${postgresHost} port=${postgresPort} user=${postgresUsr} password=${postgresPwd} dbname=${postgresDBName}"

# encrypt key
echo "" && echo "" && echo ""
PriKey=my-priv-key.pem
PriKeyPwd=123456
if [ -s ./${PriKey} ]; then
  printf "\\r ${PriKey} is exist .\\n"
else
  printf "\\r generate ${PriKey}: \\n"
  (echo ${PriKeyPwd} && echo ${PriKeyPwd}) | openssl genrsa -out ${PriKey} -aes256 2048
fi
export JFS_RSA_PASSPHRASE=${PriKeyPwd}

#
MountPoint=/mnt/jfs_${FsId}
VolumeName=my-juicefs-${FsId}

# info
echo "" && echo "" && echo ""
ps -auxf | grep -v grep | grep -i "juicefs mount"

# create
echo "" && echo "" && echo ""
ObjStoreType=file
ObjStoreBucket=/var/jfs_${FsId}/
EncryptAlgo=aes256gcm-aesgcm # aes256gcm-rsa
${JuiceFS} format \
  --storage ${ObjStoreType} \
  --bucket ${ObjStoreBucket} \
  --encrypt-root-key ./${PriKey} \
  --encrypt-algo ${EncryptAlgo} \
  --block-size 4096 \
  --compress lz4 \
  ${postgresURL}/${postgresDB} \
  ${VolumeName}

echo "" && echo "" && echo ""
tree ${ObjStoreBucket}

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
echo "" && echo "" && echo ""
tree ${MountPoint}

# read / write test
echo "" && echo "" && echo ""
echo "haha" > ${MountPoint}/file1

echo "" && echo "" && echo ""
ls -al ${MountPoint}/file1

echo "" && echo "" && echo ""
cat ${MountPoint}/file1

echo "" && echo "" && echo ""
tree ${ObjStoreBucket}

#
echo "" && echo "" && echo ""
echo "create file fs (FsId=${FsId}, ObjStoreBucket=${ObjStoreBucket}, VolumeName=${VolumeName}) over."
echo "" && echo "" && echo ""
exit 0
#end
