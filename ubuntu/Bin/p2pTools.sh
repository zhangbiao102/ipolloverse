#!/bin/bash
workPath='../'
BIN_PATH=$(cd `dirname $0`; cd ../ ; pwd )
cd `dirname $0`
cd $workPath
logPath="$PWD/log"

source /etc/profile.d/ipvRunnerProfile.sh

Start(){
    [ ! -d "$logPath" ] && mkdir $logPath
    if ! pidof cware_server >/dev/null; then
         nohup ./Tools/p2pTools/cwtools --start --path ./Tools/p2pTools  >> ./log/p2pTools.log 2>&1 &
    fi
    count=0
    until  pidof cware_server >/dev/null || [ $count -gt 10 ];do
        sleep 1
        let count=$count+1;
    done
}

Stop(){
    if pidof cware_server >/dev/null;then
        kill -9 `pidof cware_server`
    fi
}

case $1 in
   start)
       Start
       ;;
   stop)
       Stop
       ;;
   restart)
       Start
       Stop
       ;;
     *)
       echo "$0 [start|stop|restart]"
       ;;
esac
