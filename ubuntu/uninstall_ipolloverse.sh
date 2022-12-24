#!/bin/bash
# data 2022-05-29
# version 0.1

# help information

echo "uninstall script ipolloverse"
echo

printf "Are you sure install ? (y/n)"
printf "\n"
read -p "(Default: n):"  -e answer
[ -z ${answer} ] && answer="n"
if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
    echo  "remove service please wait...."
else
    exit 0
fi

projects=(nodeListen ipvRunner p2pTools nebula)

echo "[*] Removing ipolloverse"

if [ -f "/etc/profile.d/ipvRunnerProfile.sh"  ]; then
    home=$(cat  /etc/profile.d/ipvRunnerProfile.sh |awk -F'=' '{print $2}' | egrep -o '.*ipvRunner' | sort  -u)
    if [ -d "$home" ]; then
        for i in ${projects[*]}; do
            if [ -f "/etc/systemd/system/${i}.service" ]; then
                systemctl stop ${i}.service
                systemctl disable ${i}.service
                rm -f /etc/systemd/system/${i}.service
                systemctl daemon-reload
                systemctl reset-failed
	    fi
        done
        echo "[*] Removing $home directory"
        rm -rf $home
    fi
    rm -f /etc/profile.d/ipvRunnerProfile.sh
fi

echo "[*] Uninstall complete"
