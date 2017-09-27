#!/bin/bash

CMDB_URL=
CMDB_USER=
CMDB_PASS=
DELL_USER="root"
DELL_PASS="123456"
HP_USER="admin"
HP_PASS="123456"

curl -sD cookie -d "username=$CMDB_USER&password=$CMDB_PASS"  http://$CMDB_URL/user/logincheck > /dev/null 2>&1

usage() {
        echo -e "Usage: sh $0 {iplist}"
}

hp_mac() {
	sub_hp_mac() {
	        COMMAND='show /system1/network1/Integrated_NICs'
	        /usr/bin/expect -c "
	        set timeout 3
	        spawn ssh $HP_USER@$IP show /system1/network1/Integrated_NICs
	        expect \"*password:\" { send \"$HP_PASS\\r\" }
	        interact
	        "
	}
	#sub_hp_mac $IP
	MAC=`sub_hp_mac $IP |grep Port1NIC_MACAddress|awk -F "=" '{print $2}'` 
	echo $SYSIP: eth0: $MAC|tee -a mac.list
}

dell_mac() {
        MAC=`racadm -r $IP -u $DELL_USER -p $DELL_PASS getsysinfo |grep -E "NIC.Integrated.1-1-1|NIC.Embedded.1-1-1"|cut -d "=" -f2`
        echo $SYSIP: eth0: $MAC|tee -a mac.list
}

if [[ $# -eq 1 ]];then
	rm -f mac.list
	for SYSIP in `cat $1`
		do
			BRAND=`curl -sb cookie http://$CMDB_URL/cmdb/hosts/?first_ip=$SYSIP|grep -oP '(?<=device_brand":").+?(?=","device_model)'`
			sleep 1;IP=`echo $SYSIP|sed 's/10.209/172.16/'`
			#BRAND=Dell
			case $BRAND in
			        HP)
					hp_mac
			        ;;
			        Dell)
			                dell_mac
			        ;;
			        *)
			                echo "BRAND is wrong...";exit 1
			esac
		done
else
	usage
fi
