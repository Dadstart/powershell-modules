function Get-Bitrates {
<#
.SYNOPSIS
    Get bitrate statistics for multiple video files.
.DESCRIPTION
    This function analyzes multiple video files and provides statistics about their bitrates and file sizes.
.PARAMETER File
    File path to analyze. Can be passed via pipeline.
.EXAMPLE
    Get-Bitrates -File "video1.mp4"
    Analyzes the specified video file and returns bitrate statistics.
.EXAMPLE
    ls *.mkv | Get-Bitrates
    Analyzes all MKV files in the current directory and returns bitrate statistics.
.NOTES
    This function requires ffprobe to be available in the PATH.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
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
            # Calculate file size statistics
            $measureFiles = $allFiles | Measure-Object -AllStats -Property Length
            Write-Message 'Files Measure:' -Type Verbose
            $measureFiles | Format-Table
            # Calculate bitrate statistics
            if ($allBitrates.Count -gt 0) {
                $measureBitrate = $allBitrates | Measure-Object -AllStats
                Write-Message 'Bitrate Measure:' -Type Verbose
                $measureBitrate | Format-Table
                $avgBitrate = $measureBitrate.Average
            } else {
                $avgBitrate = 0
            }
            # Create output string
            $output = "{0} files | Total: {1:N2} MB | Avg: {2:N2} GB | Bitrate: {3:N2} Mbps" -f `
                $measureFiles.Count,
                ($measureFiles.Sum / 1mb),
                ($measureFiles.Average / 1gb),
                ($avgBitrate / 1mb)
            Write-Message $output -Type Verbose
            return $output
        }
        catch {
            Write-Message "Get-Bitrates function failed with error: $($_.Exception.Message)" -Type Verbose
            Write-Message "Failed to calculate bitrate statistics: $($_.Exception.Message)" -Type Error
        }
    }
}
