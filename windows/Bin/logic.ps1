$project = "logic"
$project_dir = "Tools\logic"
$MyDir = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
Set-Location -Path $MyDir  -PassThru 2>&1 >$null
$Env:nodejs = "$pwd.Path\Tools\node"
Set-Location -Path  ..\$project_dir -PassThru 2>&1 >$null
node --version
npm i