function Convert-ToConstantFrameRate {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$InputPath,
        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,
        [Parameter()]
        [ValidateRange(1, 300)]
        [double]$TargetFPS = 30.0
    )
    try {
        # Validate input file
        Write-Message "Validating input file exists: $InputPath" -Type Verbose
        if (-not (Test-Path -Path $InputPath -PathType Leaf -ErrorAction SilentlyContinue)) {
            Write-Message 'Input file validation failed - file does not exist' -Type Verbose
            Write-Message "Input file does not exist: $InputPath" -Type Error
            throw "Input file does not exist: $InputPath"
        }
        Write-Message 'Input file validation passed' -Type Verbose
        # Check if output file already exists
        Write-Message "Checking if output file already exists: $OutputPath" -Type Verbose
        if (Test-Path $OutputPath) {
            Write-Message "⚠️  Overwriting existing file: $OutputPath" -Type Verbose
        }
        else {
            Write-Message 'Output file does not exist, will be created' -Type Verbose
        }
        # Step 1: Get video codec information using ffprobe
        Write-Message 'Step 1: Getting video codec information using ffprobe' -Type Verbose
        $ffprobeArgs = @(
            '-v', 'quiet',
            '-print_format', 'json',
            '-show_streams',
            '-select_streams', 'v:0',
            $InputPath
        )
        Write-Message "ffprobe command arguments: $($ffprobeArgs -join ' ')" -Type Verbose
        $ffprobeOutput = Invoke-FFmpeg -Arguments $ffprobeArgs
        if ($ffprobeOutput.ExitCode -ne 0) {
            Write-Message "ffprobe failed with exit code: $($ffprobeOutput.ExitCode)" -Type Verbose
            Write-Message "ffprobe failed to analyze input file: $($ffprobeOutput.Output -join "`n")" -Type Error
            return
        }
        else {
            Write-Message 'ffprobe completed successfully' -Type Verbose
        }
        $streamInfo = $ffprobeOutput | ConvertFrom-Json
        $videoStream = $streamInfo.streams[0]
        $videoCodec = $videoStream.codec_name
        Write-Message "Video codec detected: $videoCodec" -Type Verbose
        Write-Message "Original video codec: $videoCodec" -Type Verbose
        # Step 2: Construct ffmpeg command
        Write-Message 'Step 2: Constructing ffmpeg command for constant frame rate conversion' -Type Verbose
        $ffmpegArgs = @(
            '-i', $InputPath,
            '-c:v', $videoCodec,
            '-r', $TargetFPS.ToString('F2'),
            '-c:a', 'copy',
            '-c:s', 'copy',
            '-y',  # Overwrite output file
            $OutputPath
        )
        Write-Message "ffmpeg command arguments: $($ffmpegArgs -join ' ')" -Type Verbose
        Write-Message "`nRunning ffmpeg to enforce CFR at $TargetFPS fps using codec '$videoCodec'..." -Type Verbose
        $ffmpegOutput = Invoke-FFmpeg -Arguments $ffmpegArgs
        if ($ffmpegOutput.ExitCode -ne 0) {
            Write-Message "ffmpeg failed with exit code: $($ffmpegOutput.ExitCode)" -Type Verbose
            Write-Message "ffmpeg failed to convert to constant frame rate: $($ffmpegOutput.Output -join "`n")" -Type Error
            return
        }
        else {
            Write-Message 'ffmpeg conversion completed successfully' -Type Verbose
            Write-Message "Successfully converted to constant frame rate: $OutputPath" -Type Verbose
        }
    }
    catch {
        Write-Message "Convert-ToConstantFrameRate function failed with error: $($_.Exception.Message)" -Type Verbose
        Write-Message "Constant frame rate conversion failed: $($_.Exception.Message)" -Type Error
        throw "Constant frame rate conversion failed: $($_.Exception.Message)"
    }
}
