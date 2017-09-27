#!/bin/bash

KEY=4000225165312

format_disk() {
        for DISK in `fdisk -l 2>&1|grep -E "$KEY"|cut -d '：' -f1|cut -d ' ' -f2|sort`
		do
			echo "Format $DISK in background..."
			parted -s $DISK mklabel gpt > /dev/null 2>&1
			parted -s $DISK mkpart primary 1 100% > /dev/null 2>&1
			mkfs.ext4 ${DISK}1 > /dev/null 2>&1 &
		done
}

mount_disk() {
	DIR=1
        for DISK in `fdisk -l 2>&1|grep -E "$KEY"|cut -d '：' -f1|cut -d ' ' -f2|sort`
		do
			UUID=`blkid|grep $DISK|cut -d' ' -f2`
			if [ ${#UUID} -eq 43 ];then
				if grep -q $UUID /etc/fstab;then
					echo -ne "\033[32mNotice\033[0m: $DISK $UUID is already in fstab...\n"
				else
					echo "$UUID /data${DIR}  ext4 defaults 1 2"|tee -a /etc/fstab
					echo "mount ${DISK}1 /data$DIR..."
					if [ ! -d /data$DIR ];then
						mkdir /data$DIR && mount ${DISK}1 /data${DIR}
					else
						#echo -ne "\033[32mNotice\033[0m: /data${DIR} is already exist...\n"
						mount ${DISK}1 /data${DIR}
					fi
				fi
				let DIR+=1
			else
				echo -ne "\033[31mError\033[0m: $DISK UUID $UUID maybe wrong...\n"
				continue
			fi
		done

}

format_disk

while true
	do
		#ps -ef|grep mkfs.ext4 | grep -v grep && { echo 'Format in progress,PLS wait...';sleep 20;break; } || { mount_disk }
		MKPRO=`ps -ef|grep mkfs.ext4 | grep -v grep`
		if [ "$MKPRO" == "" ];then
			mount_disk
			break
		else
			echo "Format in progress,PLS wait..."
			sleep 60
			continue
		fi
	done
