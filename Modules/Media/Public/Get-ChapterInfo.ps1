function Get-ChapterInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$InputFile,
        [Parameter(Position = 1)]
        [ValidateRange(1, 999)]
        [int]$ChapterNumber = 1
    )

    process {
        Write-Message "Parameters: InputFile='$InputFile', ChapterNumber=$ChapterNumber" -Type Verbose

        try {
            # Validate input file
            Write-Message "Validating input file exists: $InputFile" -Type Verbose
            if (-not (Test-Path -Path $InputFile -PathType Leaf -ErrorAction SilentlyContinue)) {
                Write-Message 'Input file validation failed - file does not exist' -Type Verbose
                Write-Message "Input file does not exist: $InputFile" -Type Error
                throw "Input file does not exist: $InputFile"
            }
            Write-Message 'Input file validation passed' -Type Verbose

            Write-Message "Getting chapter information for: $InputFile" -Type Verbose

            # Get chapter information using ffprobe
            Write-Message 'Getting chapter information using ffprobe' -Type Verbose
            $ffprobeArgs = @(
                '-v', 'quiet',
                '-print_format', 'json',
                '-show_chapters',
                $InputFile
            )
            Write-Message "ffprobe command arguments: $($ffprobeArgs -join ' ')" -Type Verbose
        
            $ffprobeOutput = Invoke-FFProbe -Arguments $ffprobeArgs
            if ($ffprobeOutput.ExitCode -ne 0) {
                Write-Message "ffprobe failed with exit code: $($ffprobeOutput.ExitCode)" -Type Verbose
                Write-Message "ffprobe failed to analyze input file (exit code: $($ffprobeOutput.ExitCode)): $($ffprobeOutput.Error -join "`n")" -Type Error
                return $null
            }
            else {
                Write-Message "ffprobe completed successfully" -Type Verbose
            }

            $chapterInfo = $ffprobeOutput.Json
            Write-Message 'Parsed chapter information from ffprobe output' -Type Verbose

            if ($chapterInfo.chapters.Count -eq 0) {
                Write-Message "No chapters found in: $InputFile" -Type Verbose
                return $null
            }
            Write-Message "Found $($chapterInfo.chapters.Count) chapters in the file" -Type Verbose

            if ($ChapterNumber -gt $chapterInfo.chapters.Count) {
                Write-Message "Only $($chapterInfo.chapters.Count) chapter(s) found in: $InputFile, but chapter $ChapterNumber was requested" -Type Verbose
                return $null
            }

            $requestedChapter = $chapterInfo.chapters[$ChapterNumber - 1]
            Write-Message "Retrieved chapter $ChapterNumber (start: $($requestedChapter.start_time)s, end: $($requestedChapter.end_time)s)" -Type Verbose
            return $requestedChapter
        }
        catch {
            Write-Message "Failed to get chapter information: $($_.Exception.Message)" -Type Error
            return $null
        }
    }
} 
