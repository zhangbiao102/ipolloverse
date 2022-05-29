# ipolloverse
##安装方式
```
LC_ALL=en_US.UTF-8 bash <(curl -s http://192.168.1.102/install_ipolloverse.sh) \
   --nodeAddr 43eac68ff697c07ec40bd52e5ed6209c7db8ac7e  \
   --nodeName test \
   --ipAddr 192.168.1.106 \
   --port1 5003 \
   --port2 10003 \
   --home /home/demo \
   --storage 5.5 \
   --measureAddr 43eac68ff697c07ec40bd52e5ed6209c7db8ac7e

--nodeAddr：页面反馈的节点地址
--home：要安装目标路径
--ip：监听ip，默认0.0.0.0
--port1：服务监听端口1，默认7777
--port2：服务监听端口2，默认11111
--storage：承诺的磁盘大小，在home路径下，单位GB
--measureAddr: 测量节点ID可选参数

http://192.168.1.104 是脚本存放位置
```

Bin 文件说明
服务器启动脚本安装时必须包含，否则会报错
```
Bin/
├── ipvRunner.sh  
├── nebula.sh
├── nodeListen.sh
└── p2pTools.sh
```
脚本运行需要依赖的软件有：
- curl
- tar
- echo
- printf
- egrep
- expr
测试通过的平台有ubuntu18.04.6 和 centos7.9


###卸载脚本

`LC_ALL=en_US.UTF-8 bash <(curl -s http://192.168.1.102/uninstall_ipolloverse.sh)`
