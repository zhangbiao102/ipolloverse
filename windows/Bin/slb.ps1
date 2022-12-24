$project = "slb"
$project_dir = "Tools\slb"
$MyDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
Set-Location -Path $MyDir  -PassThru 2>&1 >$null
$Env:nodejs = "$pwd.Path\Tools\node"
Set-Location -Path  ..\$project_dir -PassThru 2>&1 >$null

function project-init {
   $value = "powershell -file $MyDir\$project`.ps1"
   if( -not ( Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run").$project) {
       New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name $project -PropertyType String -Value $value -ErrorAction Stop  2>&1 >$null
   }
}
node --version

start  npm i 
Start-Process -WindowStyle hidden -FilePath npm -ArgumentList "run stop" -RedirectStandardOutput "..\..\log\slb.log"
Start-Process -WindowStyle hidden -FilePath npm -ArgumentList "run prod  8090" -RedirectStandardOutput  "..\..\log\slb.log"

project-init