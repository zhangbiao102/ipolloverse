import  os
import sys
import  time
import  requests
import tarfile
import zipfile
import json,ssl
import  urllib.request
import socket,ctypes
import subprocess
import  re
import wmi
cpuinfo = wmi.WMI()
CPU = cpuinfo.Win32_Processor()[0].Name

port1=777
port2=11111

configUrl='https://ecotoolstest.ipolloverse.com/ipvConfig/ipvConfig?nodeAddr='
softUrl='https://ecotools.ipolloverse.com'
#softUrl='https://ecotoolstest.ipolloverse.com'
apiPostUrl='https://gslb.ipolloverse.com'
vulkanSdkUrl='https://sdk.lunarg.com/sdk/download/1.3.231.2/linux/vulkansdk-linux-x86_64-1.3.231.2.tar.gz'

#Default value
port1 = 7777
port2 = 11111


portS=[port1,port2,8888,8081,8097,8082,8084,8080,8096,8090,'8500-8999','8100-8300',8890]
#portS=[port1,port2,8888,8081,8097,8082,8084,8096,8090]
tag=True

def extract(tar_path, target_path):
    if 'gz' in tar_path:
        try:
            tar = tarfile.open(tar_path, "r:gz")
            file_names = tar.getnames()
            for file_name in file_names:
                tar.extract(file_name, target_path)
            tar.close()
        except Exception as e:
            print(e)
    elif 'zip' in tar_path:
        try:
            file = zipfile.ZipFile(tar_path)
            file.extractall(target_path)
        except Exception as e:
            print(e)

def progressbar(url,path,fileName,progress=False):
    path =  path.replace('\\','\\\\')
    if not os.path.exists(path):
         os.mkdir(path)
    start = time.time()
    response = requests.get(url, stream=True)
    size = 0
    chunk_size = 1024
    content_size = int(response.headers['content-length'])
    try:
        if response.status_code == 200:
            size = content_size / chunk_size / 1024
            if progress:print('[   INFO  ]:\tStart download '+fileName+',[File size]:{size:.2f} MB'.format(size = content_size / chunk_size /1024))
            filepath = path+'\\'+fileName

            with open(filepath,'wb') as file:
                for data in response.iter_content(chunk_size = chunk_size):
                    file.write(data)
                    if progress:
                        size +=len(data)
                        print('\r'+'[ %s ]:%s%.2f%%' % ( fileName ,'>'*int(size*50/ content_size), float(size / content_size * 100)) ,end=' ')
        end = time.time()
        if progress:print('Download completed!,times: %.2f s' % (end - start))
    except:
        print('Error!')

def scriptsLog(statusCode:int,logInfo):
    global tag
    if  statusCode == 0 :
        print('[ SUCCESS ]:\t'+ logInfo)
    elif  statusCode == 1 :
        print("[   INFO  ]:\t"+ logInfo )
    elif  statusCode == 2 :
        print("[   WARN  ]:\t"+ logInfo)
        tag = False
    elif [ statusCode == 3 ]:
        print("[   ERROR ]:\t" + logInfo)
        tag=False

#check port
def access(port:int):
    if port < 5000 or 65535 < port:scriptsLog(2,"[port] range of ports is 5000 - 65535 : %s" % port)
    cmd = 'netstat -aon|findstr "LISTENING" |findstr ":%s "' % port
    with os.popen(cmd, 'r') as f:
        if '' != f.read():scriptsLog(2,'[port] is already used in the system : %s' % port)

def get_free_space_mb(folder):
    import ctypes
    import platform
    """ Return folder/drive free space (in bytes)
    """
    if platform.system() == 'Windows':
        free_bytes = ctypes.c_ulonglong(0)
        ctypes.windll.kernel32.GetDiskFreeSpaceExW(ctypes.c_wchar_p(folder), None, None, ctypes.pointer(free_bytes))
        return free_bytes.value/1024/1024/1024
    else:
        st = os.statvfs(folder)
        return st.f_bavail * st.f_frsize/1024/1024

def python_call_powershell(filePs):
    try:
        args = [r"powershell","-ExecutionPolicy","Unrestricted", r"%s" % filePs]
        p = subprocess.Popen(args, stdout=subprocess.PIPE)
        return  True
    except Exception as e:
        print(e)
        return False

class install():
    def __init__(self,args):
        self.home = args.home
        self.nodeAddr = args.nodeAddr
        self.nodeName = args.nodeName
        self.ipAddr = args.ipAddr
        self.port1 = args.port1
        self.port2 = args.port2
        self.storage = args.storage
        self.measureAddr = args.measureAddr

    def gethtml(self,url,data=None):
        ssl._create_default_https_context = ssl._create_unverified_context
        textmod = json.dumps(data).encode("utf-8")
        try:
            req = urllib.request.Request(url=url, data=textmod)
            res = urllib.request.urlopen(req)
            res = res.read()
            htmldata = json.loads(res)
            return htmldata
        except:
            scriptsLog(3, "http status code not 200 " + url)
            return False


    def envChk(self):
        scriptsLog(1,'Start checking the parameters you entered...')
        if is_admin() == False:
            scriptsLog(2,'Please run the script as admin user')

        self.jsonConfig =  self.gethtml(url=configUrl+self.nodeAddr)
        try:socket.inet_aton(self.ipAddr)
        except socket.error:scriptsLog(1,'%s check ip address failed!' % self.ipAddr)
        if not os.path.exists(self.home):
            os.makedirs(self.home)
        LocalStorage = int(get_free_space_mb(self.home))
        if self.storage > LocalStorage:
            tmp = """The current directory is out of space, %s free  %s GB ,
                  Space required for program installation 3 GB, 
                  The size of the allocated space is %s GB
                  """ % (self.home,LocalStorage,self.storage)
            scriptsLog(2,tmp)
        for i in portS:
            if type(i) != int:
                p = i.split('-')
                for p in range(int(p[0]),int(p[1])):access(p)
            else:access(i)
        if tag:
            scriptsLog(0,'Parameter check succeeded')
            return True
        else:
            scriptsLog(3,'The parameter check failed, please check it and try again')
            return False

    def confInfo(self):
        if self.envChk() == False: return False
        tmp = """
  Information confirmed
        Your nodeAddr      :    %s 
        Your nodeName      :    %s 
        Your public ipAddr :    %s
        Your install path  :    %s
        Your storage size  :    %sGB""" % (self.nodeAddr,self.nodeName,self.ipAddr,self.home,self.storage)
        print(tmp)
        if self.measureAddr: print("\tYour measureAddr  :    %s " % self.measureAddr)

        user_input = input('Are you sure install (yes/no): ')
        if user_input.lower() == 'yes' or user_input.lower() == 'y':
            scriptsLog(1,"Install service please wait....")
            return True
        else:
            return False

    def envInit(self):
        # download project file
        progressbar(softUrl+'/tools/ipvRunnerWin/ipvRunnerWin.zip',self.home,'ipvRunnerWin.zip',True)
        extract(self.home+'\ipvRunnerWin.zip',self.home)
        # add TestTools project  path to system PATH
        path_tmp = ''
        filename_path = ''
        for filename in os.listdir(self.home+'\ipvRunner\TestTools'):
            scriptsLog(1, 'add %s modules path to system PATH' % filename)
            filename_path = self.home + '\ipvRunner\TestTools\\' + filename
            if filename_path in sys.path: continue
            sys.path.append(filename_path)
            if path_tmp: path_tmp = path_tmp + ';' + filename_path
            else: path_tmp = filename_path
        # add nodejs project  path to system PATH
        if 'node' not in sys.path:
            filename_path = self.home + '\\ipvRunner\\Tools\\node'
            sys.path.append(filename_path)
            if path_tmp: path_tmp = path_tmp + ';' + filename_path
            else: path_tmp = filename_path

        if filename_path:
            os.system('setx path_user "%s"  2>&1 >$null' % path_tmp)
            os.system('setx path "%PATH%;%path_user%"  2>&1 >$null')

    def ipvRunner(self):
        scriptsLog(1,'start configure IpvRunner')
        if self.measureAddr: nodeType = 3333
        else: nodeType = 0
        ipvRunner_json = self.jsonConfig['ipvRunner']
        ipvRunner_json['ip'] = self.ipAddr
        ipvRunner_json['homeFolder'] = self.home + '\ipvRunner'
        ipvRunner_json['port1'] = self.port1
        ipvRunner_json['port2'] = self.port2
        ipvRunner_json['nodeName'] = self.nodeName
        ipvRunner_json['storage'] = self.storage
        ipvRunner_json['nodeType'] = nodeType
        ipvRunner_json['cpu'] = CPU
        ipvRunner_json['apps'] = self.jsonConfig['apps']
        with open(self.home + '\\ipvRunner\\ipvrunner.json' , 'w') as write_f:
            json.dump(ipvRunner_json, write_f, indent=4, ensure_ascii=False)

    def nodeListen(self):
        scriptsLog(1,'start configure nodeListen')
        node_json = self.jsonConfig['bridge']
        node_json['assignURL'] = node_json['assignURL'].replace("xxxx", str(self.port1))
        node_json['measureUrl'] = node_json['measureUrl'].replace("xxxx", str(self.port1))
        with open(self.home + '\\ipvRunner\\config.json' , 'w') as write_f:
            json.dump(node_json, write_f, indent=4, ensure_ascii=False)

    def nebula(self):
        scriptsLog(1,'start configure nebula')
        nebula_json = self.jsonConfig['network']
        progressbar(nebula_json['hostCrt'],self.home + '\\ipvRunner\\Tools\\nebula','host.crt')
        progressbar(nebula_json['hostKey'],self.home + '\\ipvRunner\\Tools\\nebula','host.key')
        progressbar(nebula_json['nodeCrt'],self.home + '\\ipvRunner\\Tools\\nebula','node.crt')
        progressbar(nebula_json['nodeYaml'],self.home + '\\ipvRunner\\Tools\\nebula','node.yaml')

    def startup_projects(self):
        projects = ['ipvRunner','nodeListen','nebula','cloudRender','slb','nginx','nanodownload','logic']
        tag = []
        for i in projects:
            if i == 'nginx':
                nginxFile=self.home + '/ipvRunner'.replace('\\' , '/')
                file_data = ""
                with open(self.home+'\\ipvRunner\\Tools\\nginx\\conf\\nginx_template.conf', "r", encoding="utf-8") as f:
                    for HH in f:
                        if 'NGINX_PATH_HOME' in HH:
                            HH = HH.replace('NGINX_PATH_HOME', nginxFile)
                        file_data += HH
                with open(self.home+'\\ipvRunner\\Tools\\nginx\\conf\\nginx.conf', "w", encoding="utf-8") as f:
                    f.write(file_data)
            try:
                Status =  python_call_powershell(self.home + '\\ipvRunner\\Bin\\%s.ps1' % i)
                scriptsLog(0, 'start  %s' % i)
                tag.append(True)
            except:
                scriptsLog(3, 'Startup failed %s' % i)
                tag.append(False)
        if False in tag: return False
        else: return True

    def apiPost(self):
        overlayIp = self.jsonConfig['ipvRunner']['overlayIp']
        tmp = {}
        for i in self.jsonConfig['apps']:
            if 'appIds' in tmp.keys(): tmp['appIds'] = '%s,%s' % (tmp['appIds'],i['appId'])
            else: tmp['appIds'] = i['appId']
            if 'appNames' in tmp.keys(): tmp['appNames'] = '%s,%s' % (tmp['appNames'],i['appName'])
            else: tmp['appNames'] = i['appName']
            tmp['appParams'] = ''
            if i['appMode'] == 1:
                if 'appParams' in tmp.keys():
                    tmp['appParams'] = '%s,%s' % (tmp['appParams'], i['appName'])
                else:
                    tmp['appParams'] = i['appName']
            if 'nodeType' in tmp.keys(): tmp['nodeType'] = '%s,%s' % (tmp['nodeType'],i['appMode'])
            else: tmp['nodeType'] = i['appMode']

        jsonData = {
            'nodeAddr': self.nodeAddr,
            'nodeType': tmp['nodeType'],
            'nodeShare':'',
            'nodeName': self.nodeName,
            'cpu': CPU,
            'gpu': 'none',
            'geo': 'none',
            'params': '{"overlayIp": %s,"exIp": %s}' % (overlayIp,self.ipAddr),
            'appIds': tmp['appIds'],
            'appNames': tmp['appNames'],
            "appParams": tmp['appParams']
            }
        if self.measureAddr is None:
            scriptsLog(0,"api report information, please wait....")
            if self.gethtml(apiPostUrl+'/user/nodeEnroll',jsonData):
                scriptsLog(0,'calculate node install SUCCESS')
                return True
        else:
            try:
                params = self.jsonConfig['params']
                jsonData = {'nodeAddr': self.measureAddr,'orgName':'none','nodeName':self.nodeName,'params': params}
                if self.gethtml(apiPostUrl + '/user/measureEnroll', jsonData):
                    scriptsLog(0, 'measure node install SUCCESS')
                    return True
            except:
                return False


    def main(self):
        if self.confInfo() == False: return False
        if self.envChk() == False: return False
        if self.envInit() == False: return False
        if self.ipvRunner() == False: return False
        if self.nodeListen() == False: return False
        if self.nebula() == False: return False
        if self.startup_projects() == False: return False
        if self.apiPost() == False: return False

def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

if __name__ == '__main__':
    import argparse
    arg = argparse.ArgumentParser("Options:")
    arg.add_argument("--nodeAddr",type=str,required=True, help="User blockchain address( eg.0xa3c46471cd252903f784dbdf0ff426f0d2abed47)")
    arg.add_argument("--measureAddr",type=str, help="User measureAddr address( eg.0xa3c46471cd252903f784dbdf0ff426f0d2abed47)")
    arg.add_argument("--nodeName",required=True, help="node name (eg. zhangsan)")
    arg.add_argument("--ipAddr",required=True,help="User public IP address (eg. 8.8.8.8)")
    arg.add_argument("--port1",default=7777, type=int, help="ipvrunner listen port1 (eg. 7777)")
    arg.add_argument("--port2",default=11111, type=int, help="ipvrunner listen port2 (eg. 11111)")
    arg.add_argument("--home",required=True, help="Installation Path (eg. D:\ipolloverse)")
    arg.add_argument("--storage",type=int,required=True, help="Commitment disk size default unit GB e.g. 500")
    args = arg.parse_args()
    aa = install(args)
    aa.main()