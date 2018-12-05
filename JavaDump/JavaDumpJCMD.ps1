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

# Get all java processes
$process = "java.exe"
$procs = Get-WmiObject Win32_Process -Filter "name = '$process'"

# Other vars
$jdk = $env:JAVA_HOME
$data = "AccelaDump\data.txt"

if(!(Test-Path "AccelaDump")){
    New-Item -Name "AccelaDump" -ItemType Directory
} else {
    if(Test-Path $data){
        Remove-Item -Path $data
    }
}

Write-Output "JAVA_HOME: $jdk"
function log{
    param([string]$content)
    Add-Content $data "$content + `n"
}

foreach ($proc in $procs) {
    $cmd = $proc.CommandLine
    # Get the AA processes - they should have "av." in the command line
    if ($cmd -like '*av.biz*' -OR $cmd -like '*av.web*') {
        Write-Output "Found AA Java Process: $cmd"
        $id = $proc.ProcessId
        log "$id - $cmd"

        if(Test-Path "AccelaDump\$id.tdump"){
            Remove-Item -path "AccelaDump\$id.tdump"
        }
        if(Test-Path "AccelaDump\$id.hprof"){
            Remove-Item -path "AccelaDump\$id.hprof"
        }
        # Thread Dump command
        $jstack = $jdk + "\jstack -l $id >> AccelaDump\$id.tdump"
        # Heap Dump command
        $jcmd = $jdk + "\jcmd $id GC.heap_dump $PSScriptRoot\AccelaDump\$id.hprof"
        Invoke-Expression $jstack
        Invoke-Expression $jcmd
    }
}

Write-Output "Creating zip file..."
Compress-Archive -Path "AccelaDump\*" -CompressionLevel Optimal -DestinationPath "AccelaDump.zip" -Force
Write-Output "Done. Please send AccelaDump.zip to support."
Invoke-Item .

Pause



