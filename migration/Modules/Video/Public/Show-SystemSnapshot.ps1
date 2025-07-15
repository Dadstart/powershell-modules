function Show-SystemSnapshot {
    param(
        [Parameter(ValueFromPipeline = $true, Position = 0)]
        [PSObject]$Snapshot,
        [switch]$SkipGPU,
        [switch]$SkipNetwork
    )
    
    # If no snapshot provided, get one
    if (-not $Snapshot) {
        $Snapshot = Get-SystemSnapshot -SkipGPU:$SkipGPU -SkipNetwork:$SkipNetwork
    }

    function Colorize($text, $color) {
        Write-Message $text -Type Verbose
    }

    function NewLine { Write-Message "" -Type Verbose }

    Write-Message "" -Type Verbose
    Write-Message "=== SYSTEM SNAPSHOT @ $($Snapshot.Timestamp) ===" -Type Verbose
    NewLine
    Colorize "CPU Usage        : " "Gray"; Colorize ("{0,6:N2}%" -f $Snapshot.CPU_UsagePct) "Yellow"; NewLine
    Colorize "Memory Usage     : " "Gray"; Colorize ("{0,6:N2}% ({1} MB / {2} MB)" -f $Snapshot.Mem_UsagePct, $Snapshot.Mem_UsedMB, $Snapshot.Mem_TotalMB) "Yellow"; NewLine
    Colorize "Disk Activity    : " "Gray"; Colorize ("{0,6:N2}%" -f $Snapshot.Disk_IOPct) "Yellow"; NewLine
    
    if (-not $SkipGPU) {
        Colorize "GPU 3D Usage     : " "Gray"; Colorize ("{0,6:N2}%" -f $Snapshot.GPU_UsagePct) "Green"; NewLine
        Colorize "GPU Memory Used  : " "Gray"; Colorize ("{0,6:N2} GB" -f $Snapshot.GPU_MemGB) "Green"; NewLine
    }
    
    if (-not $SkipNetwork) {
        Colorize "Network Throughput: " "Gray"; Colorize ("{0,6:N2} Mbps" -f $Snapshot.Net_Mbps) "Magenta"; NewLine
    }
    NewLine

    Write-Message "=== DISK SPACE ===" -Type Verbose
    $Snapshot.Disks | ForEach-Object {
        $color = if ($_.FreePct -lt $Script:DiskSpaceWarningThreshold) { "Red" } elseif ($_.FreePct -lt $Script:DiskSpaceCriticalThreshold) { "Yellow" } else { "Green" }
        Colorize "$($_.Drive): " "Gray"
        Colorize ("Used: {0,-5} GB | Free: {1,-5} GB | Total: {2,-5} GB | Free: {3,5:N1}%" -f $_.UsedGB, $_.FreeGB, $_.TotalGB, $_.FreePct) $color
        NewLine
    }
}
