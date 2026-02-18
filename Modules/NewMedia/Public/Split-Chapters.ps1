function Split-Chapters {
    <#
    .SYNOPSIS
    Splits a video file into multiple files based on chapter ranges.
    
    .DESCRIPTION
    Takes an input video file and splits it into multiple output files based on specified chapter ranges.
    Uses ffprobe to get chapter information and ffmpeg to perform the splitting.
    
    .PARAMETER InputFile
    Path to the input video file (e.g., 'M:\Video-M\Supernatural\1.1\Supernatural Season 1 Disc 1_t00.mkv')
    
    .PARAMETER ChapterRanges
    Array of hashtables or PSCustomObjects specifying chapter ranges. Each range should have:
    - Start: Starting chapter index (0-based)
    - End: Ending chapter index (0-based, inclusive)
    - OutputName: (Optional) Name for the output file (without extension)
    
    .PARAMETER OutputPath
    Directory where output files will be saved. Defaults to the same directory as the input file.
    
    .EXAMPLE
    $ranges = @(
        @{ Start = 0; End = 0; OutputName = "Episode1" },
        @{ Start = 1; End = 1; OutputName = "Episode2" }
    )
    Split-Chapters -InputFile "M:\Video-M\Supernatural\1.1\Supernatural Season 1 Disc 1_t00.mkv" -ChapterRanges $ranges
    
    .OUTPUTS
    String[]. Array of output file paths.
    #>
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$InputFile,
        
        [Parameter(Mandatory)]
        [array]$ChapterRanges,
        
        [Parameter()]
        [string]$OutputPath
    )
    
    # Validate input file exists
    if (-not (Test-Path $InputFile)) {
        throw "Input file not found: $InputFile"
    }
    
    # Set output path to input directory if not specified
    if ([string]::IsNullOrWhiteSpace($OutputPath)) {
        $OutputPath = Split-Path -Parent $InputFile
    }
    
    # Create output directory if it doesn't exist
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Get chapters from the video file
    Write-Host "Getting chapter information from: $InputFile" -ForegroundColor Cyan
    $chapters = Get-ChaptersFromVideo -InputFile $InputFile
    
    if ($chapters.Count -eq 0) {
        throw "No chapters found in video file"
    }
    
    Write-Host "Found $($chapters.Count) chapters" -ForegroundColor Green
    
    # Get input file extension for output files
    $inputExtension = [System.IO.Path]::GetExtension($InputFile)
    if ([string]::IsNullOrWhiteSpace($inputExtension)) {
        $inputExtension = ".mkv"
    }
    
    # Array to store output file paths
    $outputFiles = @()
    
    # Process each chapter range
    for ($i = 0; $i -lt $ChapterRanges.Count; $i++) {
        $range = $ChapterRanges[$i]
        
        # Validate range structure
        if ($null -eq $range.Start -or $null -eq $range.End) {
            throw "Chapter range at index $i is missing Start or End property"
        }
        
        $chapterStart = $range.Start - 1
        $chapterEnd = $range.End - 1
        
        # Validate chapter indices
        if ($chapterStart -lt 0 -or $chapterEnd -lt 0) {
            throw "Chapter indices must be non-negative. Range at index $i has Start=$chapterStart, End=$chapterEnd"
        }
        
        if ($chapterStart -ge $chapters.Count -or $chapterEnd -ge $chapters.Count) {
            throw "Chapter range out of bounds. Available chapters: 0-$($chapters.Count - 1). Range at index ${i}: ${chapterStart}-${chapterEnd}"
        }
        
        if ($chapterStart -gt $chapterEnd) {
            throw "ChapterStart ($chapterStart) must be less than or equal to ChapterEnd ($chapterEnd) for range at index $i"
        }
        
        # Generate output filename
        if ($null -ne $range.OutputName -and -not [string]::IsNullOrWhiteSpace($range.OutputName)) {
            $outputFileName = "$($range.OutputName)$inputExtension"
        } else {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
            #$outputFileName = "${baseName}_ch${chapterStart}-${chapterEnd}$inputExtension"
            $uniqueIdentifier = ("{0:D2}" -f ($i + 1))
            $outputFileName = $baseName + ".split-$uniqueIdentifier" + $inputExtension
        }
        
        $outputFile = Join-Path $OutputPath $outputFileName
        
        # Check if output file already exists
        if (Test-Path $outputFile) {
            Write-Warning "Output file already exists: $outputFile. Skipping..."
            $outputFiles += $outputFile
            continue
        }
        
        # Get timecodes for this chapter range
        $startChapter = $chapters[$chapterStart]
        $endChapter = $chapters[$chapterEnd]
        
        $startTime = $startChapter.start_time
        $endTime = $endChapter.end_time
        $duration = $endTime - $startTime
        
        # Format timecodes for ffmpeg
        $startTimeCode = Format-TimeCode -Seconds $startTime
        $durationTimeCode = Format-TimeCode -Seconds $duration
        
        Write-Host "Splitting chapters $chapterStart-$chapterEnd ($startTimeCode - $durationTimeCode) -> $outputFileName" -ForegroundColor Yellow
        
        # Build and execute ffmpeg command
        $ffmpegArgs = @(
            "-i", $InputFile
            "-ss", $startTimeCode
            "-t", $durationTimeCode
            "-map", "0"
            "-c", "copy"
            "-avoid_negative_ts", "make_zero"
            $outputFile
        )
        
        $ffmpegCommand = "ffmpeg $($ffmpegArgs -join ' ')"
        Write-Host "Executing: $ffmpegCommand" -ForegroundColor Gray
        
        & ffmpeg @ffmpegArgs
        
        if ($LASTEXITCODE -ne 0) {
            throw "ffmpeg failed with exit code $LASTEXITCODE for output file: $outputFile"
        }
        
        Write-Host "Successfully created: $outputFile" -ForegroundColor Green
        $outputFiles += $outputFile
    }
    
    return $outputFiles
}

function Get-ChaptersFromVideo {
    <#
    .SYNOPSIS
    Gets chapter information from a video file using ffprobe.
    
    .PARAMETER InputFile
    Path to the input video file.
    
    .OUTPUTS
    Array of chapter objects with start_time, end_time, and id properties.
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrWhiteSpace()]
        [string]$InputFile
    )
    
    if (-not (Test-Path $InputFile)) {
        throw "Input file not found: $InputFile"
    }
    
    # Get chapter data from ffprobe in JSON format
    $ffprobeOutput = & ffprobe -v quiet -show_chapters -of json $InputFile 2>&1
    
    if ($LASTEXITCODE -ne 0) {
        throw "ffprobe failed with exit code $LASTEXITCODE. Error: $ffprobeOutput"
    }
    
    # Parse JSON output
    $jsonData = $ffprobeOutput | ConvertFrom-Json
    $chapters = $jsonData.chapters
    
    if ($null -eq $chapters) {
        return @()
    }
    
    return $chapters
}

function Format-TimeCode {
    <#
    .SYNOPSIS
    Formats seconds into HH:MM:SS.mmm format for ffmpeg.
    
    .PARAMETER Seconds
    Time in seconds (can be decimal).
    
    .OUTPUTS
    Time string in HH:MM:SS.mmm format.
    #>
    param(
        [Parameter(Mandatory)]
        [double]$Seconds
    )
    
    $hours = [int][math]::Floor($Seconds / 3600)
    $minutes = [int][math]::Floor(($Seconds % 3600) / 60)
    $secs = $Seconds % 60
    
    # Format as HH:MM:SS.mmm (with milliseconds)
    $hoursStr = "{0:D2}" -f $hours
    $minutesStr = "{0:D2}" -f $minutes
    $secsStr = "{0:00.000}" -f $secs
    
    return "${hoursStr}:${minutesStr}:${secsStr}"
}
