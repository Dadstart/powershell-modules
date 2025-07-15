function Get-MediaStats {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline, Mandatory)]
        [string]$File
    )

    begin {
        $allFiles = @()
        $allBitrates = @()
    }

    process {
        try {
            Write-Message "Processing file: $File" -Type Verbose
            
            # Get file info for statistics
            $fileInfo = Get-Item -Path $File
            $allFiles += $fileInfo
            
            # Get bitrate for this file
            $bitrate = Get-Bitrate -Path $File
            if ($bitrate -gt 0) {
                $allBitrates += $bitrate
            }
        }
        catch {
            Write-Message "Failed to process file $File`: $($_.Exception.Message)" -Type Verbose
            Write-Message "Failed to process file $File`: $($_.Exception.Message)" -Type Error
        }
    }

    end {
        try {
            if ($allFiles.Count -eq 0) {
                Write-Message 'No files found' -Type Verbose
                return
            }

            # Calculate average bitrate
            $avgBitrate = if ($allBitrates.Count -gt 0) {
                ($allBitrates | Measure-Object -Average).Average
            } else {
                0
            }

            # Calculate file size statistics
            $stats = $allFiles | Measure-Object Length -AllStats
            
            # Create output string
            $output = '{0:N0} files | Total: {1:N2} GB | Avg: {2:N2} GB | Bitrate: {3:N2} Mbps' -f `
                $stats.Count, ($stats.Sum / 1GB), ($stats.Sum / $stats.Count / 1GB), ($avgBitrate / 1mb)
            
            # Copy to clipboard and display
            $output | Set-Clipboard
            Write-Message $output -Type Verbose
            
            return $output
        }
        catch {
            Write-Message "Get-MediaStats function failed with error: $($_.Exception.Message)" -Type Verbose
            Write-Message "Failed to calculate media stats: $($_.Exception.Message)" -Type Error
        }
    }
}
