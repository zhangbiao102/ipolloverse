#!/bin/bash
# 2022-05-18
#version 0.1 

#接口配置地址
configUrl='http://39.103.149.156:9090/ipvConfig/ipvConfig?nodeAddr='
softUrl='http://39.103.149.156:82'
apiPostUrl='https://8.142.92.172'

#Space required for program installation type int
#安装的软件大小需要是整数类型
deployerSpace=2 #unit GB

#Default is value
#默认值
port1=9999
port2=11111
ipAddr='0.0.0.0'



#print help
#打印帮助信息
Help(){    
    echo -e "\nUsage: sh $0 [OPTION]"
    echo -e "Options:"
    echo -e "[OPTION]"
    echo -e "[ --nodeAddr ]   User blockchain address                   e.g. 0xa3c46471cd252903f784dbdf0ff426f0d2abed47 "
    echo -e "[ --nodeName ]   node name                                 e.g. zhangsan-node"
    echo -e "[ --ipAddr   ]   Listen on local IP address               e.g. 192.168.1.100 "
    echo -e "[ --port1    ]   ipvrunner listen port1                    e.g. 7777"
    echo -e "[ --port2    ]   ipvrunner listen port2                    e.g. 11111"
    echo -e "[ --home     ]   Installation Path                         e.g. /home/user/ipolloverse/"
    echo -e "[ --storage  ]   Commitment disk size default unit GB      e.g. 500"
    echo -e "[ -h|--help  ]   display this help and exit \n"
}

#print scripts log
#打印脚本日志
scriptsLog(){
    statusCode=$1
    logInfo=$2
    if [ $statusCode == 0 ];then
        echo -e "[ SUCCESS ]:\t${logInfo[*]}"
    elif [ $statusCode == 1 ];then
        echo -e "[   INFO  ]:\t${logInfo[*]}"
    elif [ $statusCode == 2 ];then
        echo -e "[   WARN  ]:\t${logInfo[*]}"
    elif [ $statusCode == 3 ];then
        echo -e "\033[41;37m[   ERROR ] \033[0m\t${logInfo[*]}"
        tag=1
    fi
}

# Disable selinux
disableSelinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0 >/dev/null
    fi
}

#environment chk
#检查本地环境和你输入的参数
EnvChk(){
    tag=0
    #开始检查你输入的参数
    scriptsLog 1 "Start checking the parameters you entered..."
    #请使用root用户来运行次脚本
    [ $(id -u) != "0" ] &&  scriptsLog 3 "Please run the script as root user" 

    if ! which curl >/dev/null; then
        #脚本需要依赖curl 软件
        scriptsLog 3 "The script needs to rely on the curl software"
    fi
    
    #检查nodeAddr参数
    #check nodeAddr 
    if [ ! -z "$nodeAddr" ];then
        if [ "$(echo $nodeAddr | wc -c)" != 41   ];then
           #这个区块链地址是无效的
           scriptsLog 3 "The blockchain address is invalid :$nodeAddr"
        fi
    else
        #nodeAddr 参数不能为空
        scriptsLog 3 "[nodeAddr]  parameter cannot be empty"
    fi

    #检查测量地址
    #check measureAddr 
    if [ ! -z "$measureAddr" ];then
        if [ "$(echo $measureAddr | wc -c)" != 41   ];then
           #这个策略地址是无效的
           scriptsLog 3 "The measure address is invalid :$measureAddr"
        fi
    fi
    #检查api信息
    #check api info
    local status=$(curl -o /dev/null -s -w %{http_code} ${configUrl}${nodeAddr})
    if [ "$status" == 200 ];then
        jsonConfig=$(curl -s ${configUrl}${nodeAddr})
    else
        #http 状态码不是200，
        scriptsLog 3 "http status code not 200 "${configUrl}${nodeAddr}" \n $(curl -s ${configUrl}${nodeAddr})"
        Help
        exit
    fi
    
    #检查本地时间
    #check local time
    apiTime=$(echo ${jsonConfig} | egrep  -o 'time\":[0-9]+' | egrep -o '[0-9]+')
    timeDiff=$(expr $(date '+%s') - $apiTime)
    if [  $timeDiff -gt 60 -o  $timeDiff -lt  -60 ];then
        #请同步服务器时间，节点的时间为： 与 IpvRunner 服务器的相差多少秒
        scriptsLog 3  "Please sync server time, node local time: $(date "+%Y-%m-%d %H:%M:%S"), ${timeDiff} seconds difference from IpvRunner server"
    fi
    
    #检查ip地址
    #check ip
    if  [  -z "$(ip -4 a |grep -v 127.0.0.1 | grep -w $ipAddr)" ];then
        if [ "$ipAddr" != '0.0.0.0' ];then
            #未找到本地网卡
            scriptsLog 3 "[ipaddr] Local network card not found : $ipAddr"
        fi
    fi  
    
    #检查nodename，不能为空
    #check nodeName
    [ -z "$nodeName" ]&& scriptsLog 3 "[nodename] cannot be empty"

    #检查port端口，两个端口不能相同
    #check port
    [ "$port1" == "$port2"  ] && scriptsLog 3 "[port]  Two port cannot be repeated"
    for i in $port1 $port2;do
        if [[ "$i" =~ ^[0-9]+$ ]];then
            if  [ ! -z  "$(ss -ntlp | grep -w $i)" ];then
                #该端口已在系统中使用
                scriptsLog 3 "[port]  The port is already used in the system : $i"
            elif [  $i -le 5000 -o  "$i" -ge 65535 ];then
                 #这个端口的范围是5000到65535
                scriptsLog 3 "[port] The range of ports is 5000 - 65535 : $i"
            fi
        else
            #端口只能是整数类型
            scriptsLog 3 "[port] Ports can only be of integer type $i" 
        fi
    done
    
    #check path
    #安装路径不能为空
    if [ -z "$home" ];then
        scriptsLog 3 "[home] The installation path cannot be empty"
        exit 
        Help
    fi
    [ ! -d $home ] && mkdir -p $home

    #检查磁盘空间
    #check disk space
    deployerSpace=${deployerSpace%.*}
    if echo "$deployerSpace" | grep  '[^0-9]' >/dev/null;then
        scriptsLog 3 "program installation integer type"
    fi
        
    
    if [ -z "$storage" ];then 
        #storage 不能为空
        scriptsLog 3 "[home] storage size cannot be empty"
    else
        storage=${storage%.*}
        if echo "$storage" | grep -v '[^0-9]' >/dev/null;then
            local tmp=$(expr $storage + ${deployerSpace})
            local pathFree=$(df  $home | tail -n 1 |awk '{print $4}')
            if [ $( expr ${pathFree} / 1024 / 1024 ) -lt $tmp ];then
                #当前目录空间不足, $home 剩余空间为, 程序安装所需空间，分配空间的大小是
                scriptsLog 3 "The current directory is out of space, $home  free $( expr ${pathFree} / 1024 / 1024)GB ,Space required for program installation ${deployerSpace}GB, The size of the allocated space is $storage GB"
            fi
        else
            scriptsLog 3 "[storage] integer type ${storage}"  
        fi
    fi    
    
    if [ $tag == 0 ] ;then 
        #参数检查成功
        scriptsLog 0 "Parameter check succeeded"
    else 
        #您传递的参数检查失败，请检查后重试
        scriptsLog 3 "The parameter you passed failed to be checked, please check it and try again"
        Help
        exit
    fi
}

# Get public IP address
getIp(){
    IP=$( ip addr | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | egrep -v "^192\.168|^172\.1[6-9]\.|^172\.2[0-9]\.|^172\.3[0-2]\.|^10\.|^127\.|^255\.|^0\." | head -n 1 )
    [ -z ${IP} ] && IP=$( wget -qO- -t1 -T2 ipinfo.io/ip )
    [ -z ${IP} ] && IP=$( curl -s  cip.cc  | grep IP |awk '{print $3}' )
    [ ! -z ${IP} ] && echo ${IP} || echo
}   

#confirmed Information
confInfo(){
    EnvChk
    getIp
    #信息确认
    echo -e "\nInformation confirmed"
    echo -e "Your nodeAddr        : \033[32m ${nodeAddr} \033[0m"
    [ ! -z "$measureAddr" ] &&  echo -e "Your measureAddr     : \033[32m ${measureAddr} \033[0m"
    echo -e "Your nodeName        : \033[32m ${nodeName} \033[0m"
    echo -e "Your local ipAddr    : \033[32m ${ipAddr} \033[0m"
    echo -e "Your public ipAddr   : \033[32m ${IP} \033[0m"
    echo -e "Your server port1    : \033[32m $port1 \033[0m"
    echo -e "Your server port2    : \033[32m $port2 \033[0m"
    echo -e "Your install path    : \033[32m ${home} \033[0m"
    echo -e "Your storage size    : \033[32m ${storage} \033[0m"
    echo 
    printf "Are you sure install ? (y/n)"
    printf "\n"
    read -p "(Default: n):"  -e answer
    [ -z ${answer} ] && answer="n"
    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        #Install service please wait
        scriptsLog 1 "Install service please wait...."
    else
        exit 0
    fi
}


#download project file
downloadFile(){
   
    local downloadUrl=$1
    local savePath=$2
    local fileName=$3
    local progress=$4
    local fileType=${fileName#*.}
    #[ ${fileType} == 'tar.gz' -o ${fileType} == 'tar' ] && return 0
    [ -z "${progress}" ] && options='-s' || options='-L --progress-bar'
    [ -f "/tmp/${fileName}" ] && mv /tmp/${fileName} /tmp/${fileName}.bak
    if ! curl ${options[*]} "$downloadUrl" -o /tmp/${fileName}   ; then
        #下载文件到/tmp 失败
        scriptsLog 3 "Can't download ${projectName} file to /tmp/"
        exit 3
    fi

    [ ! -d "$savePath" ]  && mkdir -p $savePath
    if [ ${fileType} == 'tar.gz' -o ${fileType} == 'tar' ];then
        if !  tar xf /tmp/${fileName} -C ${savePath} ;then
            #无法将 /tmp/${fileName} 解压到 ${savePath} 目录
            scriptsLog 3 "Can't unpack /tmp/${fileName} to ${savePath} directory"
        fi
    else
        \cp /tmp/${fileName} $savePath
    fi
    rm -f /tmp/${fileName}
}

#创建项目系统服务
#Creating project systemd service
createProject(){
    local name=$1
    local After=$2
    #Creating project systemd service
    scriptsLog 1 "create $name systemd service"
    if [ ! -f "$home/ipvRunner/Bin/${name}.sh" ];then
        #创建服务没有找到启动脚本，请联系您的系统管理员
        scriptsLog 3 "create $name no startup script"
        scriptsLog 2 "[$name]  Please contact your system administrator"
        exit 2
    fi
    cat >/tmp/$name.service <<EOL
[Unit]
Description=$name service
After=network.target ${After[*]}

[Service]
Type=forking
ExecStart=$home/ipvRunner/Bin/${name}.sh start
ExecReload=$home/ipvRunner/Bin/${name}.sh restart
ExecStop=$home/ipvRunner/Bin/${name}.sh stop

[Install]
WantedBy=multi-user.target
EOL
    mv -bf /tmp/${name}.service /etc/systemd/system/${name}.service
    systemctl daemon-reload
    #服务器启动，并配置服务开机启动
    scriptsLog 1 "Configure $name system  startup"
    systemctl enable ${name}.service >/dev/null 2>&1
    systemctl restart ${name}.service >/dev/null 2>&1
    if !  systemctl status ${name}.service >/dev/null;then
        #启动失败
        scriptsLog 3 "Startup failed [$name]"
        scriptsLog 2 "[$name]  Please contact your system administrator"
        exit 2
    else
        scriptsLog 1  "startup SUCCESS [$name]"     
    fi
}

envInit(){
    #download project file
    scriptsLog 1 "download project file"
    downloadFile $softUrl/tools/ipvRunner.tar.gz "$home"  "ipvRunner.tar.gz" "progressTrue"
    
    #安装jq 用于处理json数据
    #install jq Used to process json data
    downloadFile $softUrl/tools/jq "$home/ipvRunner/Bin/"  "jq"
    chmod +x $home/ipvRunner/Bin/jq
    
    #create temp profile 
    >/tmp/ipvRunnerProfile.sh
    
    #下载模块
    #downloaded modules
    for((i=0;i<$(echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq  '.apps | length');i++));do
        local appName=$(echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq -r ".apps[$i].appName")
        local appUrl=$(echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq -r ".apps[$i].url")
        local appId=$(echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq -r ".apps[$i].appId")
        local appDownloadFile=$(echo ${appUrl##*/})
        scriptsLog 1 "downloaded $appName modules"
        downloadFile  $appUrl "${home}/ipvRunner/Business/${appId}"  "$appDownloadFile"  "progressTrue"
        
        scriptsLog 1 "add  $appName modules path to system PATH"
        echo "#apps ${appName}" >> /tmp/ipvRunnerProfile.sh
        echo "export PATH=${home}/ipvRunner/Business/${appId}:$PATH" >> /tmp/ipvRunnerProfile.sh
        echo  >>/tmp/ipvRunnerProfile.sh
    done
    
    #添加下面到系统变量中
    #add TestTools projcet  path to system PATH
    for i in $(ls $home/ipvRunner/TestTools);do
        scriptsLog 1 "add  $i modules path to system PATH"
        echo "#apps ${i}" >> /tmp/ipvRunnerProfile.sh
        echo "export PATH=${home}/ipvRunner/TestTools/$i:$PATH" >> /tmp/ipvRunnerProfile.sh
        echo  >>/tmp/ipvRunnerProfile.sh
    done
    
    #add Tools projcet  path to system PATH
    for i in $(ls $home/ipvRunner/Tools);do
        scriptsLog 1 "add  $i modules path to system PATH"
        echo "#apps ${i}" >> /tmp/ipvRunnerProfile.sh
        echo "export PATH=${home}/ipvRunner/Tools/$i:$PATH" >> /tmp/ipvRunnerProfile.sh
        echo  >>/tmp/ipvRunnerProfile.sh
    done
    
    
    [ ! -d "$home/ipvRunner/log" ] && mkdir -p $home/ipvRunner/log
    
    #配置权限和环境变量
    #Configure permissions and environment variables
    chmod 755 -R $home/ipvRunner
    chmod +x /tmp/ipvRunnerProfile.sh
    
    
    #添加环境脚本到
    #Adding Profile script to /etc/profile.d/ipvRunner.sh
    scriptsLog 1 "Adding project script to /etc/profile.d/ipvRunnerProfile.sh"
    mv -bf /tmp/ipvRunnerProfile.sh /etc/profile.d/ipvRunnerProfile.sh
    source /etc/profile.d/ipvRunnerProfile.sh
    rm -f /tmp/ipvRunnerProfile.sh
}


ipvRunner(){
    #开始配置该服务
    scriptsLog 1 "start configure IpvRunner"
    echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq -r '.ipvRunner' | $home/ipvRunner/Bin/jq \
        --arg v1 "$ipAddr" \
        --arg v2 "$home/ipvRunner"  \
        --arg v3 "$port1"  \
        --arg v4 "$port2" \
        --argjson data "$(echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq  -c  '.apps')" \
        '.ip=$v1 | .homeFolder=$v2 | .port1=($v3|tonumber) | .port2=($v4|tonumber) | .apps=$data' > $home/ipvRunner/ipvrunner.json
    createProject ipvRunner nodeListen service
}


nodeListen(){
    scriptsLog 1 "start configure nodeListen "
    echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq -r '.bridge'  | sed -r "s/xxxx/$port1/g" > $home/ipvRunner/config.json
    createProject nodeListen p2pTools.service
}

nebula(){
    scriptsLog 1 "start configure nebula "
    downloadFile  "$(echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq -r '.network.hostCrt')"  "$home/ipvRunner/Tools/nebula/" "host.crt" 
    downloadFile  "$(echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq -r '.network.hostKey')"  "$home/ipvRunner/Tools/nebula/" "host.key" 
    downloadFile  "$(echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq -r '.network.nodeCrt')"  "$home/ipvRunner/Tools/nebula/" "node.crt" 
    downloadFile  "$(echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq -r '.network.nodeYaml')"  "$home/ipvRunner/Tools/nebula/" "node.yaml" 
    createProject nebula 
}

p2pTools(){
    scriptsLog 1 "start configure p2pTools "
    downloadFile  "$(echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq -r '.network.keyStore')"  "$home/ipvRunner/Tools/p2pTools/" ".keystore.json" 
    downloadFile  "$(echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq -r '.network.overlay_device')"  "$home/ipvRunner/Tools/p2pTools/" ".overlay_device" 
    downloadFile  "$(echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq -r '.network.publickey')"  "$home/ipvRunner/Tools/p2pTools/" ".publickey" 
    createProject p2pTools nebula.service
}

#访问接口函数
accessApi(){
    local uri=$1
    local project=$2
    local data=$3
    returnData=`curl -s -H "Content-Type: application/json" -X POST -d     "${data[*]}" --insecure ${apiPostUrl}/${uri}`
    if [ -z "$returnData" ];then
        #接口访问呢失败
        scriptsLog 3 "api request failed : ${apiPostUrl}/$uri"
        exit 3
    else
        if [ "$(echo ${returnData[*]} | $home/ipvRunner/Bin/jq -r '.returnCode')" == '200' ];then
            scriptsLog 0 "$project node install SUCCESS"
        else
            #接口返回错误
            scriptsLog 3 "api returns error : ${returnData[*]}"
            exit 3
        fi
    fi
}

#创建post josn 参数
apiPost(){
    
    local overlayIp=$(echo ${jsonConfig[*]} |$home/ipvRunner/Bin/jq  -r '.ipvRunner.overlayIp')
    local appIds=$(echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq -r ".apps[].appId" | tr '\n' ',')
    local appNames=$(echo ${jsonConfig[*]} | $home/ipvRunner/Bin/jq -r ".apps[].appName" | tr '\n' ',')
    
    local jsonData='{ 
            "nodeAddr":"'"$nodeAddr"'",
            "compute":1000, 
            "orgName":"none" ,
            "walletAccount": "none" ,
            "nodeName": "'"$nodeName"'" , 
            "storage": '"$storage"', 
            "netBand": '40000',
            "cpu": "'"$(cat /proc/cpuinfo | grep name | cut -f2 -d: | uniq -c)"'" ,
            "gpu": "none" ,
            "geo": "none" , 
            "params" : "{\"overlayIp\":\"'"$overlayIp"'\",\"exIp\":\"'"$IP"'\",\"servicePort\":'"$port1"',\"speedTestPort\":'"$port2"'}", 
            "appIds": "'"$appIds"'", 
            "appNames": "'"$appNames"'"}'
    accessApi  user/nodeEnroll  "calculate node" "${jsonData[*]}" 
    
    #measure
    params=$(echo -e ${jsonData[*]} | $home/ipvRunner/Bin/jq -r '.params'| sed 's/\"/\\"/g')
    local jsonData='{"nodeAddr": "'"$measureAddr"'","orgName": "none","nodeName": "'"$nodeName"'","params": "'"${params[*]}"'"}'
    echo ${jsonData[*]} | $home/ipvRunner/Bin/jq -r .
    accessApi  user/measureEnroll  "measure node" "${jsonData[*]}" 
    scriptsLog 0  "Deployment  complete"
}

main(){
    confInfo
    #disableSelinux
    envInit
    nebula
    p2pTools
    ipvRunner 
    nodeListen
    apiPost
}


#normalization parameter
ARGS=`getopt -a -o h --long nodeAddr:,measureAddr:,nodeName:,ipAddr:,port1:,port2:,home:,storage:,help -- "$@"`
VALID_ARGS=$?

[ "$VALID_ARGS" != "0"  -o  -z  "$*" ] && { Help ;   exit; }

#排列参数顺序
#Arrange parameter order
eval set -- "${ARGS}"
while :
do
    case $1 in
        --nodeAddr)    nodeAddr=$2    ; shift ;;
        --measureAddr) measureAddr=$2 ; shift ;;
        --nodeName)    nodeName=$2    ; shift ;;
        --ipAddr)      ipAddr=$2      ; shift ;;
        --port1)       port1=$2       ; shift ;;
        --port2)       port2=$2       ; shift ;;
        --home)        home=$2        ; shift ;;
        --storage)     storage=$2     ; shift ;;
        -h|--help)     Help; exit 0   ; shift ;;
        --)            shift; break   ; shift ;;
    esac
    shift
done

main
