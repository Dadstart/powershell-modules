class MediaStreamInfo {
    <#
    .SYNOPSIS
        Represents a media stream from a video or audio file.

    .DESCRIPTION
        This class encapsulates information about a single media stream, including
        its index, codec information, language, title, and other metadata.
        It provides a standardized way to handle media stream data across the module.

    .PROPERTY SourceFile
        The full path to the source media file.

    .PROPERTY Index
        The zero-based index of the stream within the file.

    .PROPERTY CodecType
        The type of stream (audio, video, subtitle, data).

    .PROPERTY CodecName
        The name of the codec used for this stream.

    .PROPERTY TypeIndex
        The zero-based index of this stream within its type (e.g., first audio stream = 0).

    .PROPERTY Language
        The language code for this stream (if available).

    .PROPERTY Title
        The title of this stream (if available).

    .PROPERTY Disposition
        The disposition flags for this stream (default, attached_pic, etc.).

    .PROPERTY Tags
        Additional metadata tags for this stream.

    .EXAMPLE
        $streams = Get-MediaStreams 'video.mp4' -Type Audio
        foreach ($stream in $streams) {
            Write-Host "Audio stream $($stream.TypeIndex): $($stream.CodecName) ($($stream.Language))"
        }

    .EXAMPLE
        $stream = Get-MediaStream 'video.mp4' -Index 0 -Type Video
        if ($stream) {
            Write-Host "Video stream: $($stream.CodecName) at index $($stream.Index)"
        }

    .NOTES
        This class is used by Get-MediaStream and Get-MediaStreams to provide
        consistent return types for media stream information.
    #>

    # Properties
    [string]$SourceFile
    [int]$Index
    [string]$CodecType
    [string]$CodecName
    [int]$TypeIndex
    [string]$Language
    [string]$Title
    [object]$Disposition
    [object]$Tags

    # Constructor for creating from raw stream data
    MediaStreamInfo([string]$SourceFile, [object]$StreamData, [int]$TypeIndex) {
        $this.SourceFile = $SourceFile
        $this.Index = [int]$StreamData.index
        $this.CodecType = [string]$StreamData.codec_type
        $this.CodecName = [string]$StreamData.codec_name
        $this.TypeIndex = $TypeIndex
        $this.Language = ''
        $this.Title = ''
        if ($StreamData.tags.language) { $this.Language = [string]$StreamData.tags.language }
        if ($StreamData.tags.title) { $this.Title = [string]$StreamData.tags.title }
        $this.Disposition = $StreamData.disposition
        $this.Tags = $StreamData.tags
    }

    # Constructor for creating from individual properties
    MediaStreamInfo([string]$SourceFile, [int]$Index, [string]$CodecType, [string]$CodecName, [int]$TypeIndex, [string]$Language, [string]$Title, [object]$Disposition, [object]$Tags) {
        $this.SourceFile = $SourceFile
        $this.Index = $Index
        $this.CodecType = $CodecType
        $this.CodecName = $CodecName
        $this.TypeIndex = $TypeIndex
        $this.Language = $Language
        $this.Title = $Title
        $this.Disposition = $Disposition
        $this.Tags = $Tags
    }

    # Method to check if this is an audio stream
    [bool]IsAudio() {
        return $this.CodecType -eq 'audio'
    }

    # Method to check if this is a video stream
    [bool]IsVideo() {
        return $this.CodecType -eq 'video'
    }

    # Method to check if this is a subtitle stream
    [bool]IsSubtitle() {
        return $this.CodecType -eq 'subtitle'
    }

    # Method to check if this is a data stream
    [bool]IsData() {
        return $this.CodecType -eq 'data'
    }

    # Method to get a descriptive name for the stream
    [string]GetDisplayName() {
        $typeName = $this.CodecType.ToUpperInvariant()
        $languageName = if ($this.Language) { " ($($this.Language))" } else { '' }
        $titleName = if ($this.Title) { " - $($this.Title)" } else { '' }
        return "$typeName Stream $($this.TypeIndex)$languageName$titleName"
    }

    [string[]]GetFFMpegOutputArgs([string]$OutputPath) {
        # ffmpeg -i input.mp4
        # -map 0:a -c copy -f segment -segment_list stream_list.txt -segment_format mp3 audio_%03d.mp3
        # ffmpeg -i input.mp4
        #   -map 0:a:0 -c copy audio_eng.aac
        #   -map 0:a:1 -c copy audio_jpn.aac
        # Stream type mapping
        if ($this.CodecType -eq 'None') {
            $mapValue = "0:$($this.Index)"
        }
        else {
            $streamFilter = switch ($this.CodecType) {
                'audio' { 'a' }
                'video' { 'v' }
                'subtitle' { 's' }
                'data' { 'd' }
                default { Write-Error "Unsupported stream type: $($this.CodecType)" -ErrorAction Stop }
            }
            $mapValue = "0:$($streamFilter):$($this.TypeIndex)"
        }
            

        $quotedOutputPath = '"' + $OutputPath + '"'
        $ffmpegArgs = @(
            '-map', $mapValue,
            '-c', 'copy',
            $quotedOutputPath
        )

        return $ffmpegArgs
    }

    # Method to build ffmpeg arguments for stream extraction
    [string[]]GetFFMpegFullArgs([string]$OutputPath) {
        # Build ffmpeg arguments
        # Should result in call to ffmpeg with arguments: -i input.mkv -y -map 0:s:0 -c copy output.sup

        $quotedInputPath = '"' + $this.SourceFile + '"'
        $ffmpegArgs = @(
            '-i', $quotedInputPath,
            '-y' # Overwrite output files
        )

        $ffmpegArgs += $this.GetFFMpegOutputArgs($OutputPath)
        return $ffmpegArgs
    }

    [void]Export([string]$OutputPath, [switch]$Force) {
        Write-Verbose "Extract $($this.CodecType) stream at index $($this.TypeIndex) from '$($this.SourceFile)' to '$OutputPath'"

        # Resolve output path relative to current working directory
        if ([System.IO.Path]::IsPathRooted($OutputPath)) {
            # Absolute path - use as is
            $OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
        }
        else {
            # Relative path - resolve relative to current working directory
            $OutputPath = Join-Path (Get-Location) $OutputPath
            $OutputPath = [System.IO.Path]::GetFullPath($OutputPath)
        }
        Write-Verbose "Output path resolved: $OutputPath"

        # Create output directory if it doesn't exist
        $outputDir = Split-Path $OutputPath -Parent
        Write-Verbose "outputDir: $outputDir"
        if ($outputDir -and -not (Test-Path $outputDir)) {
            Write-Verbose "Creating output directory: $outputDir"
            if ($PSCmdlet.ShouldProcess($outputDir, 'Create directory')) {
                New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
            }
        }

        # Check if output file exists and handle Force parameter
        if (Test-Path $OutputPath) {
            if (-not $Force) {
                Write-Error "Output file already exists: $OutputPath. Use -Force to overwrite."
                return
            }
            else {
                Write-Verbose "Overwriting existing file: $OutputPath"
            }
        }


        # Build ffmpeg arguments using the extracted method
        $ffmpegArgs = $this.GetFFMpegArgs($OutputPath)

        Write-Verbose "FFmpeg command: ffmpeg $($ffmpegArgs -join ' ')"

        $progressActivity = "Exporting $($this.CodecType) Stream $($this.TypeIndex) from $($this.SourceFile)"
        try {
            Write-Progress -Activity $progressActivity -Status "Processing $($this.SourceFile)" -PercentComplete 0

            Write-Verbose "Executing: ffmpeg $($ffmpegArgs -join ' ')"

            Invoke-FFMpeg $ffmpegArgs

            Write-Progress -Activity $progressActivity -Status 'Complete' -PercentComplete 100
            Write-Verbose "Successfully exported stream to: $OutputPath"
        }
        catch {
            Write-Progress -Activity $progressActivity -Completed
            Write-Error "Failed to extract stream: $($_.Exception.Message)" -ErrorAction Stop
        }
    }

    # Override ToString method for better debugging
    [string]ToString() {
        return "MediaStreamInfo{Index=$($this.Index), Type=$($this.CodecType), Codec=$($this.CodecName), TypeIndex=$($this.TypeIndex)}"
    }
} 