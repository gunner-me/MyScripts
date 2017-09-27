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

dell_reboot() {
	echo "$IP: I am dell"
	/opt/dell/srvadmin/sbin//racadm -u$DELL_USER -p$DELL_PASS  -r $IP   config -g cfgServerInfo -o cfgServerFirstBootDevice PXE 
	/opt/dell/srvadmin/sbin/racadm -u$DELL_USER -p$DELL_PASS  -r $IP  serveraction powercycle
}

hp_reboot() {
	echo "$IP: I am HP"
	ipmitool -H $IP -I lanplus -A PASSWORD -U $HP_USER -P $HP_PASS chassis bootdev pxe
	ipmitool -H $IP -I lanplus -A PASSWORD -U $HP_USER -P $HP_PASS power cycle
}

if [[ $# -eq 1 ]];then
        for SYSIP in `cat $1`
                do
                        BRAND=`curl -sb cookie http://$CMDB_URL/cmdb/hosts/?first_ip=$SYSIP|grep -oP '(?<=device_brand":").+?(?=","device_model)'`
			#BRAND=Dell
                        sleep 1;IP=`echo $SYSIP|sed 's/10.209/172.16/'`
                        case $BRAND in
                                HP)
                                	hp_reboot 
                                ;;
                                Dell)
                                        dell_reboot
                                ;;
                                *)
                                        echo "BRAND $BRAND is wrong...";exit 1
                        esac
                done
else
        usage
fi 
