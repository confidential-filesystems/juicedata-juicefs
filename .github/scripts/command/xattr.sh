#!/bin/bash -e

source .github/scripts/common/common.sh

[[ -z "$META" ]] && META=sqlite3
source .github/scripts/start_meta_engine.sh
start_meta_engine $META
META_URL=$(get_meta_url $META)

if [[ ! -x "./juicefs-1.1" ]]; then 
    wget -q https://github.com/juicedata/juicefs/releases/download/v1.1.0/juicefs-1.1.0-linux-amd64.tar.gz
    rm /tmp/juicefs -rf && mkdir -p /tmp/juicefs
    tar -xzvf juicefs-1.1.0-linux-amd64.tar.gz -C /tmp/juicefs
    mv /tmp/juicefs/juicefs juicefs-1.1 && chmod +x juicefs-1.1 
    rm /tmp/juicefs -rf && rm juicefs-1.1.0-linux-amd64.tar.gz
    ./juicefs-1.1 version | grep "version 1.1"
fi

test_xattr(){
    umount_jfs /jfs $META_URL
    ./juicefs-1.1 format $META_URL myjfs
    ./juicefs-1.1 mount -d $META_URL /jfs --enable-xattr
    touch /jfs/test
    name="\x8ar"
    value="E$\xfe"
    setfattr -n user.$name -v $value /jfs/test
    getfattr -n user.$name /jfs/test | grep $value
    umount_jfs /jfs $META_URL
    ./juicefs mount -d $META_URL /jfs --enable-xattr
    getfattr -n user.$name /jfs/test | grep $value
    setfattr -n user.$name -v test1 /jfs/test
    getfattr -n user.$name /jfs/test | grep test1    
}

source .github/scripts/common/run_test.sh && run_test $@
