#!/bin/bash

hp_raid0() {
	echo -e "\033[32m========================> I am hp\033[0m"
	hpssacli ctrl all show config|grep Failed -A2|grep -vE '^$'
	FAILED_LD=`hpssacli ctrl all show config|grep Failed -A2|grep -vE '^$'|grep logicaldrive|awk '{print $2}'`
        if [[ $FAILED_LD -gt 0 ]];then
                echo -e "\033[32m========================> Logicaldrive Failed is $FAILED_LD\033[0m"
        else
                echo -e "\033[31m========================> Logicaldrive Failed $FAILED_LD not found...\033[0m";exit 1
        fi	
	FAILED_PD=`hpssacli ctrl all show config|grep Failed -A2|grep -vE '^$'|grep physicaldrive|awk '{print $2}'`
	if [[ $FAILED_PD =~ I: ]];then
		echo -e "\033[32m========================> Physicaldrive $FAILED_PD will be configured as raid0...\033[0m"
                read -p "========================> Confirm? [y/n]:" ANS
		if [ $ANS = y ];then
			hpssacli ctrl slot=0 ld $FAILED_LD delete forced
			if [[ $? -eq 0 ]];then
				echo -e "\033[32m========================> Logicaldrive [$FAILED_LD] delete successfully...\033[0m"
			else
				echo -e "\033[31m========================> Logicaldrive [$FAILED_LD] delete failed...\033[0m";exit 1
			fi
			hpssacli ctrl slot=0 create type=ld drives=$FAILED_PD raid=0
                        if [[ $? -eq 0 ]];then
                                echo -e "\033[32m========================> Physicaldrive [$FAILED_PD] config successfully...\033[0m"
                        else
                                echo -e "\033[31m========================> Physicaldrive [$FAILED_PD] config failed...\033[0m";exit 1
                        fi
		else
			exit 1
		fi
	else
		echo -e "\033[31m========================> Physicaldrive $FAILED_PD seems wrong...\033[0m";exit 1
	fi

}

dell_raid0() {
	echo -e "\033[32m========================> I am dell\033[0m"
        FAILED_PD=`/opt/MegaRAID/MegaCli/MegaCli64 -PDList -aAll -NoLog|grep -B 18 "Firmware state: Unconfigured"|sed -n '1,2p'|awk -F ': ' '{print $2}'|paste -s -d :`
	if [[ $FAILED_PD =~ ^32: ]];then
	        echo -e "\033[32m========================> Physicaldrive $FAILED_PD will be configured as raid0...\033[0m"
                read -p "========================> Confirm? [y/n]:" ANS
		if [ $ANS = y ];then
			/opt/MegaRAID/MegaCli/MegaCli64 -CfgLdAdd -r0[$FAILED_PD] WB Direct -a0
			if [[ $? -eq 0 ]];then
				echo -e "\033[32m========================> Physicaldrive [$FAILED_PD] config successfully...\033[0m"
			else
				echo -e "\033[31m========================> Physicaldrive [$FAILED_PD] config failed...\033[0m";exit 1
			fi 
		else
			exit 1
		fi
	else
		echo -e "\033[31m========================> Physicaldrive $FAILED_PD seems wrong...\033[0m";exit 1
	fi
}

format() {
        for i in `ls /dev/|grep -E '^sd'|sort`
               do
                       echo ${i:0:3} >> /tmp/sd.list
               done
        DISK=`cat /tmp/sd.list|uniq -c|grep 1|sed 's/\s\+/ /g'|cut -d ' ' -f3`

	if [[ "$DISK" =~ ^sd ]];then
	        echo -e "\033[32m========================> Start format $DISK as ext4 file system...\033[0m"
                read -p "========================> Confirm? [y/n]:" ANS
		if [ $ANS = y ];then
		        parted -s /dev/$DISK mklabel gpt
		        parted -s /dev/$DISK mkpart primary 1 100%
	        	mkfs.ext4 /dev/$DISK'1'
		else
			exit 1
		fi
	else
		echo -e "\033[31m========================> New disk name "$DISK" seems wrong...\033[0m";exit 1
	fi

        for i in `cat /etc/fstab |grep UUID|cut -d'=' -f2|cut -d ' ' -f1`
                do
                        blkid |grep -q $i||echo $i > /tmp/old_id;
                done

        OLD_ID=`cat /tmp/old_id`
	if [[ $OLD_ID ]];then
		echo -e "\033[32m========================> Old uuid is $OLD_ID\033[0m"
	else
		echo -e "\033[31m========================> Old uuid not found...\033[0m";exit 1
	fi

        MNT_POINT=`cat /etc/fstab |grep $OLD_ID|awk '{print $2}'`
	if [[ $MNT_POINT ]];then
		echo -e "\033[32m========================> Mount point is $MNT_POINT\033[0m"
	else
		echo -e "\033[31m========================> Mount point not found...\033[0m";exit 1
	fi

	for i in `blkid|cut -d '"' -f2`
		do
			grep -q $i /etc/fstab||echo $i > /tmp/new_id;
		done
	NEW_ID=`cat /tmp/new_id`
	if [[ $NEW_ID ]];then
		echo -e "\033[32m========================> New uuid is $NEW_ID\033[0m"
	else
		echo -e "\033[31m========================> New uuid not found...\033[0m";exit 1
	fi

        df -hl|grep -q -E "$MNT_POINT$"&&umount -f $MNT_POINT
        mount /dev/$DISK'1' $MNT_POINT/
	sed -i "s/$OLD_ID/$NEW_ID/" /etc/fstab
	NEW_LINE=`cat /etc/fstab|grep $NEW_ID`
	echo -e "\033[32m========================> /etc/fstab updated...\033[0m\n$NEW_LINE"
}


rm -f /tmp/sd.list
dmidecode|grep Vendor|grep -q Dell&&BRAND=Dell||BRAND=HP
STAMP=`date "+%Y%m%d"`
cp /etc/fstab /etc/fstab_$STAMP

case $BRAND in
	HP)
		rpm -qa|grep -q hpssacli||yum install -y hpssacli
		hp_raid0
		format
	;;
	Dell)
		rpm -qa|grep -q MegaCli||yum install -y MegaCli
		dell_raid0
		format
	;;
	*)
		echo -e "\033[31m========================> BRAND is wrong...\033[0m";exit 1
esac
