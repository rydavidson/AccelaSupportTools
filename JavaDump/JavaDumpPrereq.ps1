# Try to elevate

$wid=[System.Security.Principal.WindowsIdentity]::GetCurrent()
  $prp=new-object System.Security.Principal.WindowsPrincipal($wid)
  $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
  $IsAdmin=$prp.IsInRole($adm)
  if (!$IsAdmin)
  {  
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
    write-output "Not running in an elevated session. Attempting restart with elevated session."
    Exit
}

Set-Location $PSScriptRoot

$failed = $false
$failureLog = ""

$jdk = $env:JAVA_HOME # Set java home
# Get all java processes
$process = "java.exe"
$procs = Get-WmiObject Win32_Process -Filter "name = '$process'"

if(!(Test-Path $jdk)){
    $failed = $true
    $failureLog += "Java home not found. Set the JAVA_HOME environment variable `n"
}

$containsProcs = $false

foreach($proc in $procs){
    $containsProcs = $true
}

if(!($containsProcs)){
    $failureLog += "Could not find any running java processes `n"
}


if($failed){
    Write-Output "Failed prereq check for the following reasons:"
    Write-Output $failureLog
}

Pause