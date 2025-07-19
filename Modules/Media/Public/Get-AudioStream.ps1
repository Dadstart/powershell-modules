function Get-AudioStream {
    <#
    .SYNOPSIS
        Gets audio stream information from video files in the specified path(s).
    .DESCRIPTION
        This function scans the specified video files (MKV and other formats) and extracts audio streams
        using Get-MediaStreamCollection for efficient processing of multiple files. It filters the results 
        by CodecName and Language if specified, and returns an array of MediaStreamInfo objects representing 
        the audio streams.
    .PARAMETER Source
        One or more paths to video files or directories. Accepts pipeline input.
    .PARAMETER CodecName
        The audio codec to filter for (e.g., 'aac', 'ac3', 'dts'). Optional.
    .PARAMETER Language
        The language code to filter for (e.g., 'eng', 'spa'). Optional.
    .EXAMPLE
        Get-AudioStream -Source .\Season01 -CodecName aac -Language eng
        Gets all English AAC audio streams from video files in the Season01 directory.
    .EXAMPLE
        ls *.mkv | Get-AudioStream -Language eng
        Gets all English audio streams from MKV files in the current directory.
    .OUTPUTS
        [MediaStreamInfo[]] - Array of MediaStreamInfo objects representing audio streams.
    .NOTES
        This function requires the Video module to be loaded and depends on Get-MediaStreamCollection for 
        efficient stream extraction. The returned MediaStreamInfo objects provide methods like IsAudio(), 
        GetDisplayName(), and ToString() for easier stream manipulation and display.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Source,
        [Parameter()]
        [string]$Language = 'eng',
        [Parameter()]
        [string]$CodecName
    )
    begin {
        @(
            'Write-Message',
            'Get-Path',
            'Get-MediaStreamCollection'
        ) | Set-PreferenceInheritance
        $allFiles = @()
        $videoExtensions = @('.mkv', '.mp4', '.mov', '.avi', '.ts', '.m2ts', '.wmv', '.flv', '.webm')
    }
    process {
        foreach ($item in $Source) {
            $path = Get-Path -Path $item -ValidatePath Either
            if ((Get-Item $path).PSIsContainer) {
                # Directory: get all video files in directory
                $files = Get-ChildItem -Path $path -File | Where-Object { $videoExtensions -contains $_.Extension.ToLower() }
                $allFiles += $files.FullName
            }
            else {
                # File: check extension
                if ($videoExtensions -contains ([System.IO.Path]::GetExtension($path).ToLower())) {
                    $allFiles += $path
                }
            }
        }
    }
    end {
        if ($allFiles.Count -eq 0) {
            Write-Message "No video files found in specified sources" -Type Warning
            return @()
        }
        try {
            Write-Message "Processing $($allFiles.Count) files using Get-MediaStreamCollection" -Type Verbose
            # Use Get-MediaStreamCollection for efficient processing
            $streamCollection = $allFiles | Get-MediaStreamCollection -Type Audio
            if (-not $streamCollection -or $streamCollection.Count -eq 0) {
                Write-Message "No audio streams found in any files" -Type Verbose
                return @()
            }
            $results = @()
            # Process each file's streams
            foreach ($fileEntry in $streamCollection.GetEnumerator()) {
                $filePath = $fileEntry.Key
                $streams = $fileEntry.Value
                Write-Message "Processing $($streams.Count) audio streams from $filePath" -Type Verbose
                $filtered = $validStreams
                if ($CodecName) {
                    $filtered = $filtered | Where-Object { $_.CodecName -eq $CodecName }
                }
                if ($filtered) {
                    $results = @($results; $filtered)
                }
                Write-Message "$filePath`: $($filtered.Count) streams found" -Type Verbose
            }
            return $results
        }
        catch {
            Write-Message "Failed to process audio streams: $($_.Exception.Message)" -Type Error
            return @()
        }
    }
} 
