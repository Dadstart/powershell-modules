function Convert-VideoFile {
    [CmdletBinding()]
    <#
    .SYNOPSIS
        Converts a video file using 2-pass encoding with specific audio stream configurations.
    .DESCRIPTION
        Convert-VideoFile performs a 2-pass video conversion using libx264 with the 'slow' preset
        and 5000k bitrate. The function handles specific audio stream configurations:
        - Audio stream 2 (DTS Surround 5.1) becomes the first output stream, encoded as AAC 6-channel 384kbps
        - Audio stream 1 (DTS-HD) becomes the second output stream, copied as-is
        - Preserves metadata and chapters from the input file
        - Optimizes MP4 output with faststart flag

        The function supports pipeline input, allowing you to convert multiple files by piping them to the function.
        When using pipeline input, each file will be converted to the same output file (overwriting previous conversions).
    .PARAMETER InputFile
        The path to the input video file to convert. Accepts pipeline input and can process multiple files.
    .PARAMETER OutputFile
        The path for the output video file.
    .PARAMETER VideoBitrate
        The video bitrate in kbps. Default is 5000k.
    .PARAMETER VideoPreset
        The libx264 preset to use. Default is 'slow'.
    .PARAMETER AudioBitrate
        The bitrate for the AAC audio stream in kbps. Default is 384k.
    .PARAMETER AudioChannels
        The number of channels for the AAC audio stream. Default is 6.
    .PARAMETER CleanupPassLog
        Whether to clean up the pass log file after conversion. Default is $true.
    .EXAMPLE
        Convert-VideoFile -InputFile "C:\Videos\input.mkv" -OutputFile "C:\Videos\output.mp4"
        Converts input.mkv to output.mp4 using default settings.
    .EXAMPLE
        Convert-VideoFile -InputFile "input.mkv" -OutputFile "output.mp4" -VideoBitrate "4000k" -VideoPreset "medium"
        Converts with custom video bitrate and preset.
    .EXAMPLE
        "input1.mkv", "input2.mkv" | Convert-VideoFile -OutputFile "output.mp4"
        Converts multiple input files to the same output file (each will overwrite the previous).
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
        [string]$VideoBitrate = '5000k',

        [Parameter()]
        [ValidateSet('ultrafast', 'superfast', 'veryfast', 'faster', 'fast', 'medium', 'slow', 'slower', 'veryslow')]
        [string]$VideoPreset = 'slow',

        [Parameter()]
        [string]$AudioBitrate = '384k',

        [Parameter()]
        [int]$AudioChannels = 6,

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
        Write-Message "Video settings: libx264 preset $VideoPreset, bitrate $VideoBitrate" -Type Info
        Write-Message "Audio settings: AAC $AudioChannels-channel, bitrate $AudioBitrate" -Type Info

        # Create pass log file path
        $leafPath = Get-Path -Path $OutputFile -PathType Leaf
        $passLogFile = [System.IO.Path]::ChangeExtension($leafPath, '.ffmpeg')

        try {
            # Pass 1: Video only, no audio
            Write-Message 'Starting 2-pass encoding - Pass 1' -Type Processing
            $pass1Args = @(
                '-y',
                '-i', $inputPath,
                '-c:v', 'libx264',
                '-preset', $VideoPreset,
                '-b:v', $VideoBitrate,
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
                '-i', $inputPath,
                '-c:v', 'libx264',
                '-preset', $VideoPreset,
                '-b:v', $VideoBitrate,
                '-pass', '2',
                '-passlogfile', $passLogFile,
                # Map video stream
                '-map', '0:v:0',
                # Audio stream 2 (DTS Surround 5.1) becomes first output stream, encoded as AAC
                '-map', '0:a:1',
                '-c:a:0', 'aac',
                '-b:a:0', $AudioBitrate,
                '-ac:a:0', $AudioChannels.ToString(),
                '-metadata:s:a:0', 'title="Surround 5.1"',
                # Audio stream 1 (DTS-HD) becomes second output stream, copied as-is
                '-map', '0:a:0',
                '-c:a:1', 'copy',
                '-metadata:s:a:1', 'title="DTS-HD"',
                # Copy metadata and chapters from input
                '-map_metadata', '0',
                '-map_chapters', '0',
                # MP4 optimization
                '-movflags', '+faststart',
                $outputPath
            )

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
