#!/bin/bash

CMDB_URL=
CMDB_USER=
CMDB_PASSWORD=
DELL_USER="root"
DELL_PASS="123456"
HP_USER="admin"
HP_PASS="123456"

curl -sD cookie -d "username=$CMDB_USER&password=$CMDB_PASSWORD"  http://$CMDB_URL/user/logincheck > /dev/null 2>&1

#racadm serveraction 
	#graceshutdown   - perform a graceful shutdown of server
	#powerdown       - power server off
	#powerup         - power server on
	#powercycle      - perform server power cycle
	#hardreset       - force hard server power reset
	#powerstatus     - display current power status of server

#ipmitool
	#chassis power Commands: status, on, off, cycle, reset, diag, soft

usage() {
        echo -e "Usage: sh $0 {iplist} {serveraction:reboot,poweron,poweroff,status}"
}

if [[ $# -eq 2 ]];then
        for SYSIP in `cat $1`
                do
                        BRAND=`curl -sb cookie http://$CMDB_URL/cmdb/hosts/?first_ip=$SYSIP|grep -oP '(?<=device_brand":").+?(?=","device_model)'`
			#BRAND=HP
                        sleep 1;IP=`echo $SYSIP|sed 's/10.209/172.16/'`;echo $IP
			if [[ $BRAND =~ "HP" ]];then
	                        case $2 in
	                                poweron)
	                                	/usr/bin/ipmitool -H $IP -I lanplus -A PASSWORD -U $HP_USER -P $HP_PASS power on 
	                                ;;
	                                poweroff)
	                                        /usr/bin/ipmitool -H $IP -I lanplus -A PASSWORD -U $HP_USER -P $HP_PASS power off
	                                ;;
	                                reboot)
						/usr/bin/ipmitool -H $IP -I lanplus -A PASSWORD -U $HP_USER -P $HP_PASS power cycle
					;;
					status)
						/usr/bin/ipmitool -H $IP -I lanplus -A PASSWORD -U $HP_USER -P $HP_PASS power status
					;;
					*)	
	                                        echo "action $2 is not supported...";exit 1
				esac
			elif [[ $BRAND =~ "Dell" ]];then
				case $2 in
                                        poweron)
						/opt/dell/srvadmin/sbin/racadm -u$DELL_USER -p$DELL_PASS  -r $IP  serveraction powerup
                                        ;;
                                        poweroff)
						/opt/dell/srvadmin/sbin/racadm -u$DELL_USER -p$DELL_PASS  -r $IP  serveraction powerdown
                                        ;;
                                        reboot)
						/opt/dell/srvadmin/sbin/racadm -u$DELL_USER -p$DELL_PASS  -r $IP  serveraction powercycle
                                        ;;
                                        status)
						/opt/dell/srvadmin/sbin/racadm -u$DELL_USER -p$DELL_PASS  -r $IP  serveraction powerstatus
                                        ;;
                                        *)
                                                echo "action $2 is not supported...";exit 1
				esac

			else
				echo "BRAND $BRAND is wrong...";exit 1
			fi
                done
else
        usage
fi 
