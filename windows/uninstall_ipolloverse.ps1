$projects = 'nebula','nodeListen','ipvRunner','nanodownload','nginx','cloudRender','node','slb'
$disconnect = 'https://gslb.ipolloverse.com/user/nodeDisconnect'

function remove_path($str1) {
   if(( Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run")."$str1") {
      $str_path =  ( Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run")."$str1".split()[-1]
      remove-itemproperty -path HKCU:\Software\Microsoft\Windows\CurrentVersion\Run -name $str1 
      $str_path -match '(\w\:.+ipvRunner)\\Bin\\\w+\.ps1'
      $scripts_home = $Matches[1]
      if($scripts_home){ return $scripts_home
      }else{ return $false}
   }
}

$answer = Read-Host "Are you sure to uninstall ipolloverse? (yes/no)"
if( $answer -eq 'yes'  -or $answer -eq 'y') {
   echo  "remove service please wait...."
}else{
   exit
}


for($i=0; $i -lt $projects.Length; $i++)   
{   
    $tmp = remove_path $projects[$i]
    if ( $tmp ){
       $home_path = $tmp[1]
    }
    Get-Process -Name $projects[$i] 2>&1 >$null
    if ($?) {
       Get-Process -Name $projects[$i] | Stop-Process
    }
}

if( ! "$home_path"){ exit }

if (Test-Path -Path $home_path) {
    Set-Location -Path $home_path  -PassThru 2>&1 >$null
    $appSettings = Get-Content "$home_path\ipvrunner.json" | ConvertFrom-Json
    $nodeId = $appSettings.nodeId
    Set-Location -Path  $env:USERPROFILE  -PassThru 2>&1 >$null
    Remove-Item $home_path -Recurse -Force
}else {
    exit
}

#revme path
if ($env:path_user){
   [System.Environment]::SetEnvironmentVariable('path_user', '', 'user')
}

if($nodeId){
   $apiData = @{"nodeAddr"=$nodeId} | ConvertTo-Json
   $returnData = Invoke-WebRequest -UseBasicParsing $disconnect -ContentType "application/json" -Method POST -Body $apiData
   $returnCode =  $returnData.Content | ConvertFrom-Json
   if ($returnCode.returnCode -eq 200){
       echo '[SUCCEEDED] api request ok'
   }else{
       echo "[ERROR] api request failed : $disconnect"
       echo "$returnData"
   }
}