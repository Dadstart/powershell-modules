function Export-Chapter {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$InputFile,
        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputFile,
        [Parameter(Mandatory, Position = 2)]
        [ValidateRange(1, 999)]
        [int]$ChapterNumber,
        [Parameter()]
        [ValidateRange(1, 3600)]
        [int]$MaxDuration = 300
    )
    try {
        # Validate input file
        Write-Message "Validating input file exists: $InputFile" -Type Verbose
        if (-not (Test-Path -Path $InputFile -PathType Leaf -ErrorAction SilentlyContinue)) {
            Write-Message 'Input file validation failed - file does not exist' -Type Verbose
            Write-Message "Input file does not exist: $InputFile" -Type Error
            throw "Input file does not exist: $InputFile"
        }
        Write-Message 'Input file validation passed' -Type Verbose
        # Check if output file already exists
        Write-Message "Checking if output file already exists: $OutputFile" -Type Verbose
        if (Test-Path $OutputFile) {
            Write-Message "⚠️  Overwriting existing file: $OutputFile" -Type Verbose
        }
        else {
            Write-Message 'Output file does not exist, will be created' -Type Verbose
        }
        Write-Message "Extracting chapter from: $InputFile" -Type Verbose
        # Get chapter information
        Write-Message "Getting chapter information for chapter $ChapterNumber" -Type Verbose
        $chapterInfo = Get-ChapterInfo -InputFile $InputFile -ChapterNumber $ChapterNumber
        if (-not $chapterInfo) {
            Write-Message 'Failed to get chapter information' -Type Verbose
            Write-Message "Failed to get chapter information for chapter $ChapterNumber" -Type Error
            return
        }
        Write-Message 'Successfully retrieved chapter information' -Type Verbose
        # Calculate duration
        Write-Message 'Calculating chapter duration' -Type Verbose
        $fullDuration = [double]$chapterInfo.end_time - [double]$chapterInfo.start_time
        $duration = [Math]::Min($fullDuration, $MaxDuration)
        Write-Message "Chapter duration: $fullDuration seconds, will extract: $duration seconds" -Type Verbose
        Write-Message "Chapter duration: $fullDuration seconds, extracting first $duration seconds" -Type Verbose
        # Build ffmpeg command to extract chapter with audio and subtitles
        Write-Message 'Building ffmpeg command for chapter extraction' -Type Verbose
        $ffmpegArgs = @(
            '-i', $InputFile,
            '-ss', ('{0:F3}' -f $chapterInfo.start_time),
            '-t', ('{0:F3}' -f $duration),
            '-c', 'copy',
            '-avoid_negative_ts', 'make_zero',
            '-y',
            $OutputFile
        )
        Write-Message "ffmpeg command arguments: $($ffmpegArgs -join ' ')" -Type Verbose
        if ($PSCmdlet.ShouldProcess("$InputFile ➡️ $OutputFile", 'Extract chapter')) {
            Write-Message 'Executing ffmpeg chapter extraction' -Type Verbose
            $ffmpegOutput = Invoke-FFmpeg -Arguments $ffmpegArgs
            Write-Message "ffmpeg completed with exit code: $($ffmpegOutput.ExitCode)" -Type Verbose
            Write-Message "ffmpeg output $($ffmpegOutput.Output?.Length)" -Type Verbose
            Write-Message "ffmpeg error $($ffmpegOutput.Error?.Length)" -Type Verbose
            if ($ffmpegOutput.ExitCode -ne 0) {
                Write-Message 'ffmpeg chapter extraction failed' -Type Verbose
                Write-Message "ffmpeg failed with exit code: $($ffmpegOutput.ExitCode)" -Type Error
                return
            }
            Write-Message 'ffmpeg chapter extraction completed successfully' -Type Verbose
            # Verify output file was created
            Write-Message "Verifying output file was created: $OutputFile" -Type Verbose
            if (Test-Path -Path $OutputFile -ErrorAction SilentlyContinue) {
                $fileSize = (Get-Item $OutputFile).Length
                Write-Message "Output file created successfully, size: $fileSize bytes" -Type Verbose
                Write-Message "Successfully extracted chapter to: $OutputFile" -Type Verbose
                return $true
            }
            else {
                Write-Message 'Output file was not created despite successful ffmpeg execution' -Type Verbose
                Write-Message 'Chapter extraction completed but output file was not created' -Type Error
                return $false
            }
        }
    }
    catch {
        Write-Message "Chapter extraction failed: $($_.Exception.Message)" -Type Error
    }
} 
