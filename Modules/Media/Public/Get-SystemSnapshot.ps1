function Get-SystemSnapshot {
    param(
        [switch]$SkipGPU,
        [switch]$SkipNetwork
    )
    # Batch counter queries for better performance
    $counters = @(
        '\Processor(_Total)\% Processor Time',
        '\Memory\Available MBytes',
        '\PhysicalDisk(_Total)\% Disk Time'
    )
    # Get all basic counters in one batch
    $counterData = Get-Counter -Counter $counters -ErrorAction SilentlyContinue
    # Extract values with error handling
    $cpu = if ($counterData) { 
        ($counterData.CounterSamples | Where-Object {$_.Path -like '*Processor*'}).CookedValue 
    } else { 0 }
    $memAvailable = if ($counterData) { 
        ($counterData.CounterSamples | Where-Object {$_.Path -like '*Memory*'}).CookedValue 
    } else { 0 }
    $diskIO = if ($counterData) { 
        ($counterData.CounterSamples | Where-Object {$_.Path -like '*PhysicalDisk*'}).CookedValue 
    } else { 0 }
    # Memory calculation
    $memTotal = (Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue).TotalPhysicalMemory / 1MB
    $memUsed = $memTotal - $memAvailable
    $memPct  = if ($memTotal -gt 0) { ($memUsed / $memTotal) * 100 } else { 0 }
    # Disk Space - use faster WMI query
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue | ForEach-Object {
        [PSCustomObject]@{
            Drive   = $_.DeviceID
            UsedGB  = [math]::Round(($_.Size - $_.FreeSpace)/1GB,2)
            FreeGB  = [math]::Round($_.FreeSpace/1GB,2)
            TotalGB = [math]::Round($_.Size/1GB,2)
            FreePct = [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
        }
    }
    # GPU - use try/catch for potentially slow counters
    $gpuLoad = 0
    $gpuMem = 0
    if (-not $SkipGPU) {
        try {
            $gpuCounters = Get-Counter '\GPU Engine(*engtype_3D)\Utilization Percentage' -ErrorAction Stop
            $gpuLoad = $gpuCounters.CounterSamples | Measure-Object CookedValue -Sum | Select-Object -ExpandProperty Sum
        } catch {
            # GPU counters not available or too slow
        }
        try {
            $gpuMemCounters = Get-Counter '\GPU Process Memory(*)\Local Usage' -ErrorAction Stop
            $gpuMem = $gpuMemCounters.CounterSamples | Measure-Object CookedValue -Sum | Select-Object -ExpandProperty Sum
        } catch {
            # GPU memory counters not available or too slow
        }
    }
    $gpuMemGB = $gpuMem / 1GB
    # Network - use try/catch for potentially slow counters
    $netTotal = 0
    if (-not $SkipNetwork) {
        try {
            $netCounters = Get-Counter '\Network Interface(*)\Bytes Total/sec' -ErrorAction Stop
            $netTotal = $netCounters.CounterSamples | Measure-Object CookedValue -Sum | Select-Object -ExpandProperty Sum
        } catch {
            # Network counters not available or too slow
        }
    }
    $netMbps = ($netTotal * 8) / 1MB
    # Additional system health metrics
    # System uptime
    $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).LastBootUpTime
    $uptimeHours = $uptime.TotalHours
    # Process count
    $processCount = (Get-Process -ErrorAction SilentlyContinue).Count
    # Handle count
    $handleCount = (Get-Process -ErrorAction SilentlyContinue | Measure-Object -Property HandleCount -Sum).Sum
    # Thread count
    $threadCount = (Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $_.Threads.Count } | Measure-Object -Sum).Sum
    # Page file usage
    $pageFile = Get-CimInstance Win32_PageFileUsage -ErrorAction SilentlyContinue | Select-Object -First 1
    $pageFileUsed = if ($pageFile) { $pageFile.AllocatedBaseSize } else { 0 }
    $pageFileTotal = if ($pageFile) { $pageFile.AllocatedBaseSize + $pageFile.CurrentUsage } else { 0 }
    $pageFilePct = if ($pageFileTotal -gt 0) { ($pageFileUsed / $pageFileTotal) * 100 } else { 0 }
    # Temperature monitoring (if available)
    $cpuTemp = 0
    $gpuTemp = 0
    try {
        # Try to get CPU temperature via WMI
        $cpuTemp = (Get-CimInstance MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" -ErrorAction SilentlyContinue | 
                   Select-Object -First 1).CurrentTemperature
        if ($cpuTemp) {
            $cpuTemp = ($cpuTemp / 10) - 273.15  # Convert from 10ths of Kelvin to Celsius
        }
    } catch {
        # Temperature monitoring not available
    }
    # System events in last minute (errors and warnings)
    $recentEvents = 0
    try {
        $recentEvents = (Get-WinEvent -FilterHashtable @{
            LogName = 'System'
            Level = 2,3  # Error and Warning
            StartTime = (Get-Date).AddMinutes(-1)
        } -ErrorAction SilentlyContinue).Count
    } catch {
        # Event log access not available
    }
    # Battery status (for laptops)
    $batteryLevel = $null
    $batteryStatus = $null
    try {
        $battery = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($battery) {
            $batteryLevel = $battery.EstimatedChargeRemaining
            $batteryStatus = $battery.BatteryStatus
        }
    } catch {
        # Battery info not available
    }
    # Disk health indicators
    $diskHealth = @()
    try {
        $physicalDisks = Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue
        foreach ($disk in $physicalDisks) {
            $health = [PSCustomObject]@{
                Model = $disk.Model
                SizeGB = [math]::Round($disk.Size / 1GB, 1)
                Status = $disk.Status
                MediaType = $disk.MediaType
            }
            $diskHealth += $health
        }
    } catch {
        # Disk health info not available
    }
    return [PSCustomObject]@{
        Timestamp     = Get-Date
        CPU_UsagePct  = [math]::Round($cpu, 2)
        Mem_UsedMB    = [math]::Round($memUsed, 0)
        Mem_TotalMB   = [math]::Round($memTotal, 0)
        Mem_UsagePct  = [math]::Round($memPct, 2)
        Disk_IOPct    = [math]::Round($diskIO, 2)
        GPU_UsagePct  = [math]::Round($gpuLoad, 2)
        GPU_MemGB     = [math]::Round($gpuMemGB, 2)
        Net_Mbps      = [math]::Round($netMbps, 2)
        Uptime_Hours  = [math]::Round($uptimeHours, 2)
        Process_Count = $processCount
        Handle_Count  = $handleCount
        Thread_Count  = $threadCount
        PageFile_UsedMB = [math]::Round($pageFileUsed, 0)
        PageFile_TotalMB = [math]::Round($pageFileTotal, 0)
        PageFile_UsagePct = [math]::Round($pageFilePct, 2)
        CPU_Temp_C    = [math]::Round($cpuTemp, 1)
        Recent_Events = $recentEvents
        Battery_Level = $batteryLevel
        Battery_Status = $batteryStatus
        Disks         = $disks
        Disk_Health   = $diskHealth
    }
}
