# ipolloverse

## 安装方式

```
.\install_ipolloverse.exe -h
--nodeAddr：页面反馈的节点地址
--home：要安装目标路径
--ip：客户端公网地址
--port1：服务监听端口1，默认7777
--port2：服务监听端口2，默认11111
--storage：承诺的磁盘大小，在home路径下，单位GB
--measureAddr: 测量节点ID可选参数
```

### 卸载脚本

`.\ uninstall_ipolloverse.ps1`

install_ipolloverse.py 是安装脚本的python文件，并生成：install_ipolloverse.exe 

`pyinstaller-F install_ipolloverse.py` #生成exe文件
