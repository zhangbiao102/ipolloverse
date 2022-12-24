$project = "nebula"
$project_dir = "Tools\nebula"
$MyDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
Set-Location -Path $MyDir  -PassThru 2>&1 >$null
Set-Location -Path ../$project_dir -PassThru 2>&1 >$null

$Proj_args =  $args

function project-init {
   $value = "powershell -file $MyDir\$project`.ps1"
   if( -not ( Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run").$project) {
       New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $project -PropertyType String -Value $value -ErrorAction Stop  2>&1 >$null
   }
}

function  project-restart {
     project-stop
     project-start
}

function  project-stop {
    Get-Process -Name "$project"  2>&1 >$null
    if ($?) {
       Get-Process -Name "$project" | Stop-Process
       return $true
    }
}

function  project-status {
    Get-Process -Name "$project"  2>&1 >$null
    if ($?) {
       return $true
    }else{
       return $false
    }
}


function  project-start {
    Get-Process -Name "$project"  2>&1 >$null
    if ($?) {
       return $true
    }else{
       Start-Process -WindowStyle hidden -FilePath  .\nebula.exe -ArgumentList " -config node.yaml" -RedirectStandardOutput "..\..\log\nebula.log" 2>&1 >$null
       if ($?) {
          return $true
       } else {
          return $false
       }
   }
}

project-init
project-start

if ( $Proj_args.Count  -eq 0 ){
   project-init
   project-start
}elseIf  ( $Proj_args.Count  -eq 1) { 
   if ( $Proj_args[0]  -eq  'start'){
       project-start
   }elseIf ( $Proj_args[0]  -eq  'restart'){
       project-restart
   }elseIf ($Proj_args[0]  -eq  'stop'){
       project-stop
   }elseIf ($Proj_args[0]  -eq  'status'){
       project-status
   }else{
      echo "scripts [start|stop|restart]"
   }
}else{
    echo "scripts [start|stop|restart]"
}