ConditionPathIsMountPoint="$1"
count=0
while ! mount | grep $ConditionPathIsMountPoint | grep JuiceFS
do
    sleep 3
    count=`expr $count + 1`
    if test $count -eq 10
    then
        echo "timed out!"
        exit 1
    fi
done
echo "$(date "+%Y-%m-%d %H:%M:%S")"
echo "succeed in checking mount point $ConditionPathIsMountPoint"
if [ -n "${subpath}" ]; then
	if [ -n "${capacity}" ]; then
		if [ "${community}" == ce ]; then
			echo "set quota in ${subpath}"
			/usr/local/bin/juicefs quota > /dev/null;
			if [ $? -eq 0 ]; then
				/usr/local/bin/juicefs quota set ${metaurl} --path ${quotaPath} --capacity ${capacity} &
			fi
		fi
		if [ "${community}" == ee ]; then
			echo "set quota in ${subpath}"
			/usr/bin/juicefs quota > /dev/null; if [ $? -eq 0 ]; then /usr/bin/juicefs quota set ${name} --path ${quotaPath} --capacity ${capacity}; fi;
		fi
	fi
fi
