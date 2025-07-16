function Get-MultipleAudioStreams {
    <#
    .SYNOPSIS
        Finds video files with multiple audio streams of the specified language.
    .DESCRIPTION
        This function scans video files and identifies those with multiple audio streams
        of the specified language. It returns a MediaStreamInfoCollection organized by file,
        making it easy to process files with complex audio configurations.
    .PARAMETER File
        The video file to analyze. Accepts pipeline input.
    .PARAMETER Language
        The language code to filter for (e.g., 'eng', 'spa'). Default is 'eng'.
    .PARAMETER WriteHost
        If specified, writes processing information to the host.
    .EXAMPLE
        Get-MultipleAudioStreams -File "movie.mkv" -Language "eng"
        Gets all English audio streams from the specified file.
    .EXAMPLE
        Get-ChildItem *.mkv | Get-MultipleAudioStreams -Language "spa"
        Gets all Spanish audio streams from MKV files in the current directory.
    .OUTPUTS
        [MediaStreamInfoCollection] - Collection where keys are file paths and values are arrays of MediaStreamInfo objects.
    .NOTES
        This function requires the Video module to be loaded and depends on Get-MediaStreamCollection for 
        efficient stream extraction. The returned MediaStreamInfo objects provide methods like IsAudio(), 
        GetDisplayName(), and ToString() for easier stream manipulation and display.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$File,
        [Parameter()]
        [string]$Language = 'eng',
        [Parameter()]
        [switch]$WriteHost
    )
    begin {
        $allFiles = @()
    }
    process {
        if (-not $File) {
            Write-Message "No file specified, skipping." -Type Warning
            return
        }
        $allFiles += $File
    }
    end {
        if ($allFiles.Count -eq 0) {
            Write-Message "No files specified, getting all MKV files in current directory" -Type Verbose
            $allFiles = Get-ChildItem *.mkv | Select-Object -ExpandProperty FullName
        }
        if ($allFiles.Count -eq 0) {
            Write-Message "No files found to process" -Type Verbose
            return @{}
        }
        Write-Message "Processing $($allFiles.Count) files for multiple audio streams" -Type Verbose
        try {
            # Use Get-MediaStreamCollection for efficient processing
            $streamCollection = Get-MediaStreamCollection -Paths $allFiles -Type Audio -Language $Language
            if (-not $streamCollection -or $streamCollection.Count -eq 0) {
                Write-Message "No audio streams found in any files" -Type Verbose
                return @{}
            }
            $results = @{}
            # Process each file's streams to find those with multiple streams
            foreach ($fileEntry in $streamCollection.GetEnumerator()) {
                $filePath = $fileEntry.Key
                $streams = $fileEntry.Value
                Write-Message "Processing file: $filePath with language: $Language" -Type Debug
                if ($WriteHost) {
                    Write-Message "Processing: $filePath" -Type Processing
                }
                if ($WriteHost) {
                    $streamsOutput = ($streams | ForEach-Object { $_.GetDisplayName() }) -join ', '
                    Write-Message "Audio Streams ($($streams.Count)): $streamsOutput" -Type Processing
                }
                # Only process files with 2 or more audio streams of the specified language
                if ($streams.Count -le 1) {
                    Write-Message "Skipping $filePath because it only has $($validStreams.Count) $Language stream(s)" -Type Verbose
                    continue
                }
                Write-Message "Found $($streams.Count) $Language audio streams in $filePath" -Type Verbose
                # Add to results
                $results[$filePath] = $streams
                if ($WriteHost) {
                    Write-Message "Added $($strams.Count) streams for $filePath" -Type Warning
                }
            }
            return $results
        }
        catch {
            Write-Message "Failed to process multiple audio streams: $($_.Exception.Message)" -Type Error
            return @{}
        }
    }
} 
