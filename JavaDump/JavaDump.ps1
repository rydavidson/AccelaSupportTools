# Try to elevate

$wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$prp = new-object System.Security.Principal.WindowsPrincipal($wid)
$adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
$IsAdmin = $prp.IsInRole($adm)
if (!$IsAdmin) {  
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
    write-output "Not running in an elevated session. Attempting restart with elevated session."
    Exit
}


function log {
    param([string]$content)
    Write-Output $content
    Add-Content $log "$content`n"
}

function prereqCheck {
    $failed = $false
    $failureLog = ""
    
    if (!(Test-Path $jdk)) {
        $failed = $true
        $failureLog += "Java home not found. Set the JAVA_HOME environment variable`n"
    }
    
    $containsProcs = $false
    
    foreach ($proc in $procs) {
        $containsProcs = $true
    }
    
    if (!($containsProcs)) {
        $failureLog += "Could not find any running java processes`n"
    }
    
    
    if ($failed) {
        log "Failed prereq check for the following reasons:"
        log $failureLog
        Pause
        exit
    }   

}



Set-Location $PSScriptRoot

# Get all java processes
$process = "java.exe"
$procs = Get-WmiObject Win32_Process -Filter "name = '$process'"

# Other vars
$jdk = $env:JAVA_HOME # Set java home
$data = "AccelaDump\data.txt" # Set the data.txt file
$log = "AccelaDump\log.txt" # Set the log file

prereqCheck

if (!(Test-Path "AccelaDump")) {
    New-Item -Name "AccelaDump" -ItemType Directory
}
else {
    if (Test-Path $data) {
        Remove-Item -Path $data
    }
}

log "JAVA_HOME: $jdk"

if (!$jdk.Contains("bin")){
    $jdk += "\bin"
}


foreach ($proc in $procs) {
    $cmd = $proc.CommandLine
    # Get the AA processes - they should have "av." in the command line
    if ($cmd -like '*av.biz*' -OR $cmd -like '*av.web*' -OR $cmd -like '*av.cfmx*') {
        log "Found AA Java Process: $cmd"
        $id = $proc.ProcessId
        log "$id - $cmd"

        if (Test-Path "AccelaDump\$id.tdump") {
            Remove-Item -path "AccelaDump\$id.tdump"
        }
        if (Test-Path "AccelaDump\$id.hprof") {
            Remove-Item -path "AccelaDump\$id.hprof"
        }
        # Thread Dump command
        $jstack = "&`"$jdk\jstack.exe`" -l $id >> AccelaDump\$id.tdump"

        # Heap Dump command     
        $jmap = "&`"$jdk\jmap.exe`" -dump:file=AccelaDump\$id.hprof $id"
        
        # Run the commands
        Invoke-Expression $jstack
        Invoke-Expression $jmap

        $jmapFailed = $false

        if(!(Test-Path AccelaDump\$id.hprof)){
            $jmapFailed = $true
            $jmap = $jdk + "\jcmd $id GC.heap_dump $PSScriptRoot\AccelaDump\$id.hprof"
            log "Jmap failed, using jcmd instead to get heap dump"
            Invoke-Expression $jmap
        }
    }
}

log "Creating zip file..."
Compress-Archive -Path "AccelaDump\*" -CompressionLevel Optimal -DestinationPath "AccelaDump.zip" -Force
log "Done. Please send AccelaDump.zip to support."
Invoke-Item .

Pause



