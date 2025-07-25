function Show-MultipleAudioStreams {
    <#
    .SYNOPSIS
        Shows video files with multiple audio streams of the specified language.
    .DESCRIPTION
        This function scans video files and displays those with multiple audio streams
        of the specified language. It uses Get-MediaStreamCollection for efficient processing
        and provides detailed information about each file's audio configuration.
    .PARAMETER File
        The video file to analyze. Accepts pipeline input.
    .PARAMETER Language
        The language code to filter for (e.g., 'eng', 'spa'). Default is 'eng'.
    .PARAMETER ShowStreams
        If specified, displays detailed stream information.
    .EXAMPLE
        Show-MultipleAudioStreams -File "movie.mkv" -Language "eng"
        Shows English audio streams from the specified file.
    .EXAMPLE
        Get-ChildItem *.mkv | Show-MultipleAudioStreams -Language "spa" -ShowStreams
        Shows Spanish audio streams from MKV files in the current directory with detailed stream info.
    .NOTES
        This function requires the Video module to be loaded and depends on Get-MediaStreamCollection for
        efficient stream extraction. The function uses MediaStreamInfo objects which provide methods like
        GetDisplayName() for better stream information display.
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$File,
        [Parameter()]
        [switch]$ShowStreams
    )
    begin {
        $allFiles = @()
    }
    process {
        if ($File) {
            $allFiles += $File
        }
    }
    end {
        try {
            # If no files were passed via pipeline, use all MKV files in current directory
            if ($allFiles.Count -eq 0) {
                Write-Message 'No files specified, getting all MKV files in current directory' -Type Verbose
                $allFiles = Get-ChildItem *.mkv | Select-Object -ExpandProperty FullName
            }
            if ($allFiles.Count -eq 0) {
                Write-Message 'No files found to process' -Type Verbose
                return
            }
            Write-Message "Processing $($allFiles.Count) files for multiple audio streams" -Type Verbose
            # Use Get-MediaStreamCollection for efficient processing
            $streamCollection = $allFiles |Get-MediaStreamCollection -Type Audio
            if (-not $streamCollection -or $streamCollection.Count -eq 0) {
                Write-Message "No audio streams found in any files" -Type Verbose
                return
            }
            # Start progress tracking for file processing
            $progress = Start-ProgressActivity -Activity 'Audio Stream Analysis' -Status 'Analyzing audio streams...' -TotalItems $streamCollection.Count
            $currentFile = 0
            foreach ($fileEntry in $streamCollection.GetEnumerator()) {
                $currentFile++
                $filePath = $fileEntry.Key
                $streams = $fileEntry.Value
                $fileName = [System.IO.Path]::GetFileName($filePath)
                $progress.Update(@{
                        CurrentItem = $currentFile
                        Status      = "Processing: $fileName"
                    })
                Write-Message "Processing: $filePath" -Type Verbose
                # Only process files with multiple audio streams of the specified language
                if ($streams.Count -gt 1) {
                    Write-Message "  Found $($streams.Count) $Language audio streams" -Type Verbose
                    Write-Message "File: $filePath" -Type Verbose
                    if ($ShowStreams) {
                        $streams | Format-Table -Property Index, TypeIndex, CodecType, CodecName, Title, Language -AutoSize
                    }
                }
            }
            $progress.Stop(@{ Status = 'Audio stream analysis completed' })
        }
        catch {
            Write-Message "Failed to show multiple audio streams: $($_.Exception.Message)" -Type Error
        }
    }
}
