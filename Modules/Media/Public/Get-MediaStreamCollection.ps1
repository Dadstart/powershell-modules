enum StreamType {
    All
    Audio
    Video
    Subtitle
}

function Get-MediaStreamCollection {
    <#
    .SYNOPSIS
        Retrieves a MediaStreamInfoCollection containing streams from one or more media files.

    .DESCRIPTION
        This function scans one or more media files using ffprobe and returns a MediaStreamInfoCollection
        that organizes MediaStreamInfo objects by their source file. Each file (key) contains an array
        of MediaStreamInfo objects for that file.

    .PARAMETER Path
        Path to one or more media files. Accepts pipeline input.

    .PARAMETER Type
        Type of stream to retrieve ('Audio', 'Video', 'Subtitle', or 'All').
        Default is 'All'.

    .EXAMPLE
        Get-MediaStreamCollection 'video1.mkv', 'video2.mkv'
        # Returns a MediaStreamInfoCollection with streams from both files.

    .EXAMPLE
        Get-MediaStreamCollection 'video.mkv' -Type Audio
        # Returns a MediaStreamInfoCollection with only audio streams from 'video.mkv'.

    .EXAMPLE
        Get-ChildItem -Filter "*.mp4" | Get-MediaStreamCollection -Type Video
        # Returns a MediaStreamInfoCollection with video streams from all MP4 files.

    .EXAMPLE
        $collection = Get-MediaStreamCollection 'movie.mkv'
        $audioStreams = $collection.GetAudioStreams()
        $videoStreams = $collection.GetVideoStreams()
        
        foreach ($filePath in $collection.Keys) {
            $streams = $collection[$filePath]
            Write-Host "File: $filePath has $($streams.Count) streams"
        }

    .OUTPUTS
        [MediaStreamInfoCollection]
        Returns a MediaStreamInfoCollection where:
        - Keys are file paths (strings)
        - Values are arrays of MediaStreamInfo objects for each file

    .NOTES
        Requires ffmpeg/ffprobe to be installed and available in the system PATH.
        This function is more efficient than Get-MediaStreams when working with multiple files
        as it organizes streams by their source files automatically.
    #>
    [CmdletBinding()]
    [OutputType([MediaStreamInfoCollection])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline)]
        [string[]]$Path,
        [Parameter(Position = 1)]
        [StreamType]$Type = [StreamType]::All
    )
    
    begin {
        Write-Debug "Parameters: $($PSBoundParameters | ConvertTo-Json)"
        $collection = [MediaStreamInfoCollection]::new()
    }

    process {
        # Define streamTypeString here so it's accessible in the process block
        $streamTypeString = $Type.ToString().ToLowerInvariant()
        
        foreach ($filePath in $Path) {
            # Resolve path to absolute path
            if ([System.IO.Path]::IsPathRooted($filePath)) {
                $resolvedPath = $filePath
            }
            else {
                $resolvedPath = Join-Path (Get-Location) $filePath
            }

            # Validate the file path before proceeding
            if (-not (Test-Path -Path $resolvedPath -PathType Leaf)) {
                Write-Error "The file path '$resolvedPath' does not exist or is not a valid file." -ErrorAction Stop
            }

            Write-Verbose "Processing file: $resolvedPath"

            try {
                # Get all streams from the file using ffprobe
                Write-Verbose 'Running ffprobe to get stream information'
                $quotedPath = '"' + $resolvedPath + '"'
                $processResult = Invoke-FFProbe '-show_streams', $quotedPath
                if ($processResult.ExitCode) {
                    Write-Error "Get-MediaStreamCollection: Failed to get media streams from '$resolvedPath'. Exit code: $($processResult.ExitCode)"
                    continue
                }

                $streams = $processResult.Json.streams
                $allStreams = $streams

                # Skip if no streams found
                if (-not $allStreams) {
                    Write-Verbose "No streams found in file '$resolvedPath'"
                    continue
                }

                Write-Verbose "Found $($allStreams.Count) total streams in '$resolvedPath'"

                # Filter streams based on type
                $filteredStreams = @()
                $typeIndex = 0

                foreach ($stream in $allStreams) {
                    # Check if stream matches the requested type
                    $matchesType = ($Type -eq [StreamType]::All) -or ($stream.codec_type -eq $streamTypeString)
                    if ($matchesType) {
                        Write-Verbose "Processing stream $($stream.index) of type $($stream.codec_type) from '$resolvedPath'"

                        # Create MediaStreamInfo object
                        $mediaStream = [MediaStreamInfo]::new($resolvedPath, $stream, $typeIndex)
                        $filteredStreams += $mediaStream
                        $typeIndex++
                    }
                }

                # Add the filtered streams to the collection
                if ($filteredStreams.Count -gt 0) {
                    $collection.Add($resolvedPath, $filteredStreams)
                    Write-Verbose "Added $($filteredStreams.Count) filtered streams of type '$Type' from '$resolvedPath' to collection"
                }
                else {
                    Write-Verbose "No streams of type '$Type' found in '$resolvedPath'"
                }
            }
            catch {
                Write-Error "Failed to get media streams from '$resolvedPath': $($_.Exception.Message)" -ErrorAction Continue
            }
        }
    }
    
    end {
        Write-Verbose "Returning MediaStreamInfoCollection with $($collection.Count) files"
        return $collection
    }
} 