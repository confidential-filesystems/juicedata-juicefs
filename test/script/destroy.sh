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
JuiceFS=${CurrFsDir}/juicefs
JuiceFS=../../juicefs

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

# destroy
echo "" && echo "" && echo ""
FsUuid=$(${JuiceFS} status ${postgresURL}/${postgresDB} | jq -r .Setting.UUID)
echo FsUuid=${FsUuid}

echo "" && echo "" && echo ""
${JuiceFS} umount ${MountPoint}

echo "" && echo "" && echo ""
(echo y) | ${JuiceFS} destroy \
  --encrypt-root-key ./${PriKey} \
  ${postgresURL}/${postgresDB} ${FsUuid}

echo "" && echo "" && echo ""
ps -auxf | grep -v grep | grep -i "juicefs mount"
echo "" && echo "" && echo ""
tree ${MountPoint}

#
# echo q | psql --command "DROP DATABASE ${postgresDBName}" "host=${postgresHost} hostaddr=${postgresHost} port=${postgresPort} user=${postgresUsr} password=${postgresPwd}"

rm -rf ${CurrFsDir}/

#
echo "" && echo "" && echo ""
echo "destroy fs (FsId=${FsId}) over."
echo "" && echo "" && echo ""
exit 0
#end
