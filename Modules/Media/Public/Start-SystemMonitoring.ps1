function Start-SystemMonitoring {
    param(
        [int]$IntervalSeconds = 60,
        [string]$OutputPath = "$env:USERPROFILE\Desktop",
        [switch]$SkipGPU,
        [switch]$SkipNetwork,
        [switch]$Quiet
    )
    # Validate interval
    if ($IntervalSeconds -lt 10) {
        Write-Message 'Interval too short, setting to minimum of 10 seconds' -Type Warning
        $IntervalSeconds = 10
    }
    # Create output directory if it doesn't exist
    Get-Path -Path $OutputPath -PathType Parent -Create Directory | Out-Null
    $OutputPath = Get-Path -Path $OutputPath, 'SystemMonitoring.csv' -PathType Absolute
    # Initialize CSV file with headers
    $headers = @(
        'Timestamp',
        'CPU_UsagePct',
        'Mem_UsedMB',
        'Mem_TotalMB', 
        'Mem_UsagePct',
        'Disk_IOPct',
        'GPU_UsagePct',
        'GPU_MemGB',
        'Net_Mbps',
        'Uptime_Hours',
        'Process_Count',
        'Handle_Count',
        'Thread_Count',
        'PageFile_UsedMB',
        'PageFile_TotalMB',
        'PageFile_UsagePct',
        'CPU_Temp_C',
        'Recent_Events',
        'Battery_Level',
        'Battery_Status'
    )
    # Add disk headers for each disk
    $sampleSnapshot = Get-SystemSnapshot -SkipGPU:$SkipGPU -SkipNetwork:$SkipNetwork
    foreach ($disk in $sampleSnapshot.Disks) {
        $headers += "Disk_$($disk.Drive)_UsedGB"
        $headers += "Disk_$($disk.Drive)_FreeGB"
        $headers += "Disk_$($disk.Drive)_TotalGB"
        $headers += "Disk_$($disk.Drive)_FreePct"
    }
    # Create CSV file with headers if it doesn't exist
    if (-not (Test-Path $OutputPath)) {
        $headers -join ',' | Out-File -FilePath $OutputPath -Encoding UTF8
    }
    Write-Message 'System monitoring started...' -Type Verbose
    Write-Message "Interval: $IntervalSeconds seconds" -Type Verbose
    Write-Message "Output file: $OutputPath" -Type Verbose
    Write-Message 'Press Ctrl+C to stop monitoring' -Type Verbose
    Write-Message '' -Type Verbose
    # Display headers
    if (-not $Quiet) {
        $headerDisplay = $headers -join ' | '
        Write-Message $headerDisplay -Type Verbose
        Write-Message ('-' * $headerDisplay.Length) -Type Verbose
    }
    $iteration = 0
    try {
        while ($true) {
            $iteration++
            $startTime = Get-Date
            # Get system snapshot
            $snapshot = Get-SystemSnapshot -SkipGPU:$SkipGPU -SkipNetwork:$SkipNetwork
            # Start progress tracking for disk data processing
            $diskProgress = Start-ProgressActivity -Activity 'Disk Processing' -Status 'Processing disk data...' -TotalItems $snapshot.Disks.Count -Id 2 -ParentId 1
            $currentDisk = 0
            # Prepare CSV row
            $csvRow = @(
                $snapshot.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'),
                $snapshot.CPU_UsagePct,
                $snapshot.Mem_UsedMB,
                $snapshot.Mem_TotalMB,
                $snapshot.Mem_UsagePct,
                $snapshot.Disk_IOPct,
                $snapshot.GPU_UsagePct,
                $snapshot.GPU_MemGB,
                $snapshot.Net_Mbps,
                $snapshot.Uptime_Hours,
                $snapshot.Process_Count,
                $snapshot.Handle_Count,
                $snapshot.Thread_Count,
                $snapshot.PageFile_UsedMB,
                $snapshot.PageFile_TotalMB,
                $snapshot.PageFile_UsagePct,
                $snapshot.CPU_Temp_C,
                $snapshot.Recent_Events,
                $snapshot.Battery_Level,
                $snapshot.Battery_Status
            )
            # Add disk data
            foreach ($disk in $snapshot.Disks) {
                $currentDisk++
                $diskProgress.Update(@{ CurrentItem = $currentDisk; Status = "Processing disk: $($disk.Drive)" })
                $csvRow += $disk.UsedGB
                $csvRow += $disk.FreeGB
                $csvRow += $disk.TotalGB
                $csvRow += $disk.FreePct
            }
            $diskProgress.Stop(@{ Status = 'Disk processing completed' })
            # Write to CSV
            $csvRow -join ',' | Out-File -FilePath $OutputPath -Append -Encoding UTF8
            # Display to screen
            if (-not $Quiet) {
                $displayRow = @(
                    $snapshot.Timestamp.ToString('HH:mm:ss'),
                    "$($snapshot.CPU_UsagePct)%",
                    "$([math]::Round($snapshot.Mem_UsedMB/1024,1))GB",
                    "$([math]::Round($snapshot.Mem_TotalMB/1024,1))GB",
                    "$($snapshot.Mem_UsagePct)%",
                    "$($snapshot.Disk_IOPct)%",
                    "$($snapshot.GPU_UsagePct)%",
                    "$($snapshot.GPU_MemGB)GB",
                    "$($snapshot.Net_Mbps)Mbps",
                    "$($snapshot.Uptime_Hours) hours",
                    "$($snapshot.Process_Count)",
                    "$($snapshot.Handle_Count)",
                    "$($snapshot.Thread_Count)",
                    "$([math]::Round($snapshot.PageFile_UsedMB/1024,1))GB",
                    "$([math]::Round($snapshot.PageFile_TotalMB/1024,1))GB",
                    "$($snapshot.PageFile_UsagePct)%",
                    "$($snapshot.CPU_Temp_C)°C",
                    "$($snapshot.Recent_Events)",
                    "$($snapshot.Battery_Level)%",
                    "$($snapshot.Battery_Status)"
                )
                # Add disk info (just free space percentage for display)
                foreach ($disk in $snapshot.Disks) {
                    $displayRow += "$($disk.Drive):$($disk.FreePct)%"
                }
                $displayLine = $displayRow -join ' | '
                # Color code based on usage levels
                $color = 'White'
                if ($snapshot.CPU_UsagePct -gt 80 -or $snapshot.Mem_UsagePct -gt 80) {
                    $color = 'Red'
                }
                elseif ($snapshot.CPU_UsagePct -gt 60 -or $snapshot.Mem_UsagePct -gt 60) {
                    $color = 'Yellow'
                }
                # Additional warnings for new metrics
                if ($snapshot.CPU_Temp_C -gt 80 -or $snapshot.PageFile_UsagePct -gt 80 -or $snapshot.Recent_Events -gt 5) {
                    $color = 'Red'
                }
                elseif ($snapshot.CPU_Temp_C -gt 70 -or $snapshot.PageFile_UsagePct -gt 60 -or $snapshot.Recent_Events -gt 2) {
                    $color = 'Yellow'
                }
                Write-Message $displayLine -Type Verbose
            }
            # Calculate sleep time to maintain consistent interval
            $elapsed = (Get-Date) - $startTime
            $sleepTime = [math]::Max(0, $IntervalSeconds - $elapsed.TotalSeconds)
            if ($sleepTime -gt 0) {
                Start-Sleep -Seconds $sleepTime
            }
        }
    }
    catch [System.Management.Automation.PipelineStoppedException] {
        Write-Message "`nMonitoring stopped by user." -Type Verbose
    }
    catch {
        Write-Message "Error during monitoring: $($_.Exception.Message)" -Type Error
    }
    finally {
        Write-Message "`nMonitoring stopped. Data saved to: $OutputPath" -Type Verbose
        Write-Message "Total iterations: $iteration" -Type Verbose
    }
} 
