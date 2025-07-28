function Convert-VideoFile {
    [CmdletBinding()]
    <#
    .SYNOPSIS
        Converts a video file using 2-pass encoding with configurable audio stream processing.

    .DESCRIPTION
        Convert-VideoFile performs a 2-pass video conversion using libx264 with configurable settings.
        The function supports flexible audio stream configuration using AudioStreamConfig objects,
        allowing you to encode or copy audio streams with custom settings.

        Features:
        - 2-pass video encoding with libx264
        - Configurable audio stream processing (encode or copy)
        - Pipeline support for batch processing
        - Metadata and chapter preservation
        - MP4 optimization with faststart flag

    .PARAMETER InputFile
        The path to the input video file to convert. Accepts pipeline input and can process multiple files.

    .PARAMETER OutputFile
        The path for the output video file.

    .PARAMETER VideoEncoding
        VideoEncodingConfig object defining video encoding parameters.
        If not specified, uses default VBR configuration (5000k bitrate, slow preset).

    .PARAMETER VideoBitrate
        The video bitrate in kbps. Default is 5000k. (Legacy parameter, use VideoEncoding instead)

    .PARAMETER VideoPreset
        The libx264 preset to use. Default is 'slow'. (Legacy parameter, use VideoEncoding instead)

    .PARAMETER AudioStreams
        Array of AudioStreamConfig objects defining how to process audio streams.
        If not specified, uses default configuration (stream 1 -> AAC, stream 0 -> copy).

    .PARAMETER CleanupPassLog
        Whether to clean up the pass log file after conversion. Default is $true.

    .EXAMPLE
        Convert-VideoFile -InputFile "input.mkv" -OutputFile "output.mp4"
        Converts with default VBR configuration (5000k bitrate, slow preset).

    .EXAMPLE
        $videoConfig = New-VideoEncodingConfig -CRF 23 -Preset 'slow'
        Convert-VideoFile -InputFile "input.mkv" -OutputFile "output.mp4" -VideoEncoding $videoConfig
        Converts with CRF 23 quality-based encoding.

    .EXAMPLE
        $audioConfigs = @(
            (New-AudioStreamConfig -InputStreamIndex 1 -Codec 'aac' -Bitrate '384k' -Channels 6 -Title 'Surround 5.1'),
            (New-AudioStreamConfig -InputStreamIndex 0 -Title 'DTS-HD' -Copy)
        )
        Convert-VideoFile -InputFile "input.mkv" -OutputFile "output.mp4" -AudioStreams $audioConfigs
        Converts with custom audio stream configurations.

    .EXAMPLE
        $videoConfig = New-VideoEncodingConfig -Bitrate '8000k' -Preset 'veryslow' -Profile 'high' -Level '4.1'
        Convert-VideoFile -InputFile "input.mkv" -OutputFile "output.mp4" -VideoEncoding $videoConfig
        Converts with high-quality VBR encoding and specific profile/level.

    .EXAMPLE
        Get-ChildItem -Path "C:\Videos" -Filter "*.mkv" | Convert-VideoFile -OutputFile "C:\Output\converted.mp4"
        Converts all MKV files in a directory to a single output file.

    .OUTPUTS
        None. The function outputs status messages using Write-Message.

    .NOTES
        This function requires ffmpeg to be installed and available in the system PATH.
        The function performs a 2-pass encoding process for optimal quality.
        Pass log files are automatically cleaned up after successful conversion.
    #>
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter()]
        [VideoEncodingConfig]$VideoEncoding,

        [Parameter()]
        [string]$VideoBitrate = '5000k',

        [Parameter()]
        [ValidateSet('ultrafast', 'superfast', 'veryfast', 'faster', 'fast', 'medium', 'slow', 'slower', 'veryslow')]
        [string]$VideoPreset = 'slow',

        [Parameter()]
        [AudioStreamConfig[]]$AudioStreams,

        [Parameter()]
        [bool]$CleanupPassLog = $true
    )

    begin {
        foreach ($function in @('Invoke-FFMpeg', 'Invoke-Process', 'Get-Path', 'Write-Message')) {
            $PSDefaultParameterValues["$function`:Verbose"] = $VerbosePreference
            $PSDefaultParameterValues["$function`:Debug"] = $DebugPreference
        }

        # Initialize pipeline processing variables
        $pipelineInputs = @()
        $processedCount = 0

        # Set up default video encoding configuration if none provided
        if (-not $VideoEncoding) {
            $VideoEncoding = [VideoEncodingConfig]::new($VideoBitrate, $VideoPreset)
        }

        # Set up default audio configuration if none provided
        if (-not $AudioStreams) {
            $AudioStreams = @(
                [AudioStreamConfig]::new(1, 'aac', '384k', 6, 'Surround 5.1'),
                [AudioStreamConfig]::new(0, 'DTS-HD')
            )
        }
    }

    process {
        # Validate and resolve input file path
        $inputPath = Get-Path -Path $InputFile -PathType Absolute -ValidatePath File
        $outputPath = Get-Path -Path $OutputFile -PathType Absolute

        # Track pipeline inputs
        $pipelineInputs += $inputPath
        $processedCount++

        Write-Message "Converting $inputPath to $outputPath" -Type Processing
        if ($pipelineInputs.Count -gt 1) {
            Write-Message "Processing file $processedCount of $($pipelineInputs.Count) in pipeline" -Type Info
        }
        Write-Message "Video encoding: $VideoEncoding" -Type Info
        Write-Message 'Audio configuration:' -Type Info
        foreach ($audioConfig in $AudioStreams) {
            Write-Message "  $audioConfig" -Type Info
        }

        # Create pass log file path
        $leafPath = Get-Path -Path $OutputFile -PathType Leaf
        $passLogFile = [System.IO.Path]::ChangeExtension($leafPath, '.ffmpeg')

        try {
            # Pass 1: Video only, no audio
            Write-Message 'Starting 2-pass encoding - Pass 1' -Type Processing
            $pass1Args = @(
                '-y',
                '-i', $inputPath
            )

            # Add video encoding arguments from configuration
            $pass1Args += $VideoEncoding.GetFFmpegArgs()

            # Add pass-specific arguments
            $pass1Args += @(
                '-pass', '1',
                '-passlogfile', $passLogFile,
                '-an',  # No audio
                '-sn',  # No subtitles
                '-f', 'null',
                'NUL'
            )

            $result = Invoke-FFMpeg -Arguments $pass1Args
            if ($result.ExitCode -ne 0) {
                Write-Message "Pass 1 failed: $($result.Error)" -Type Error
                throw "Pass 1 failed with exit code $($result.ExitCode)"
            }

            Write-Message 'Pass 1 completed successfully' -Type Success

            # Pass 2: Full conversion with audio streams
            Write-Message 'Starting 2-pass encoding - Pass 2' -Type Processing
            $pass2Args = @(
                '-y',
                '-i', $inputPath
            )

            # Add video encoding arguments from configuration
            $pass2Args += $VideoEncoding.GetFFmpegArgs()

            # Add pass-specific arguments
            $pass2Args += @(
                '-pass', '2',
                '-passlogfile', $passLogFile,
                # Map video stream
                '-map', '0:v:0'
            )

            # Add audio stream configurations
            for ($i = 0; $i -lt $AudioStreams.Count; $i++) {
                $audioConfig = $AudioStreams[$i]

                # Map the audio stream
                $pass2Args += '-map', "0:a:$($audioConfig.InputStreamIndex)"

                if ($audioConfig.Copy) {
                    # Copy stream as-is
                    $pass2Args += "-c:a:$i", 'copy'
                } else {
                    # Encode stream
                    $pass2Args += "-c:a:$i", $audioConfig.Codec
                    if ($audioConfig.Bitrate) {
                        $pass2Args += "-b:a:$i", $audioConfig.Bitrate
                    }
                    if ($audioConfig.Channels) {
                        $pass2Args += "-ac:a:$i", $audioConfig.Channels.ToString()
                    }
                }

                # Add metadata
                $pass2Args += "-metadata:s:a:$i", "title=`"$($audioConfig.Title)`""
            }
            # Copy metadata and chapters from input
            $pass2Args += '-map_metadata', '0'
            $pass2Args += '-map_chapters', '0'

            # MP4 optimization
            $pass2Args += '-movflags', '+faststart'
            $pass2Args += $outputPath

            $result = Invoke-FFMpeg -Arguments $pass2Args
            if ($result.ExitCode -ne 0) {
                Write-Message "Pass 2 failed: $($result.Error)" -Type Error
                throw "Pass 2 failed with exit code $($result.ExitCode)"
            }

            Write-Message 'Pass 2 completed successfully' -Type Success

            # Clean up pass log file if requested
            if ($CleanupPassLog -and (Test-Path $passLogFile)) {
                Remove-Item $passLogFile -Force
                Write-Message 'Cleaned up pass log file' -Type Verbose
            }

            # Verify output file exists
            if (Test-Path $outputPath) {
                $fileSize = (Get-Item $outputPath).Length
                $fileSizeMB = [math]::Round($fileSize / 1MB, 2)
                Write-Message "Conversion completed successfully - Output file: $($outputPath) ($fileSizeMB MB)" -Type Success
            } else {
                Write-Message 'Conversion failed - Output file not found' -Type Error
                throw 'Output file was not created'
            }
        }
        catch {
            Write-Message "Conversion failed: $($_.Exception.Message)" -Type Error
            throw
        }
        finally {
            # Clean up pass log file on error if it exists
            if ($CleanupPassLog -and (Test-Path $passLogFile)) {
                Remove-Item $passLogFile -Force -ErrorAction SilentlyContinue
                Write-Message 'Cleaned up pass log file after error' -Type Verbose
            }
        }
    }

    end {
        # Provide summary for pipeline processing
        if ($pipelineInputs.Count -gt 1) {
            Write-Message "Pipeline processing completed. Processed $processedCount files to $outputPath" -Type Success
        }
    }
}
