function Invoke-BonusContentProcessing {
    <#
    .SYNOPSIS
        Processes bonus content by detecting audio stream types and converting them with appropriate settings.
    .DESCRIPTION
        Analyzes video files in the input directory, categorizes them by audio stream type (Surround 5.1, Stereo, Mono),
        converts each type using HandBrake with appropriate audio encoding settings, and renames audio streams
        to match their type. Files with multiple audio streams of the same language are skipped.
    .PARAMETER Path
        The directory containing original video files to process.
    .PARAMETER Destination
        The directory where converted files will be saved.
    .PARAMETER Language
        The language code for audio streams to process. Default is 'eng'.
    .PARAMETER Quiet
        When specified, suppresses progress and the final success message. Only errors and warnings are shown.
    .EXAMPLE
        Invoke-BonusContentProcessing -Path "C:\Bonus" -Destination "C:\Converted"
    .EXAMPLE
        Invoke-BonusContentProcessing -Path "C:\Bonus" -Destination "C:\Converted" -Language "spa"
    .EXAMPLE
        Get-ChildItem "C:\Videos" -Directory | Invoke-BonusContentProcessing -Destination "C:\Converted"
    .NOTES
        This function requires the Video module to be installed and available.
        Files with multiple audio streams of the same language will be skipped.
        Files with unknown audio stream types will be skipped.
    .LINK
        https://github.com/dadstart/video-modules
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,
        [Parameter()]
        [switch]$Force,
        [Parameter()]
        [switch]$Quiet
    )
    begin {
        # Set default parameters for called functions
        $@(
            'Get-AudioStream',
            'Get-MediaExtension',
            'Export-MediaStream'
        ) | Set-PreferenceInheritance
        Write-Message 'Starting bonus content processing' -Type Verbose
        Write-Message "Original directory: $Path" -Type Verbose
        Write-Message "Output directory: $Destination" -Type Verbose
        Write-Message "Language: $Language" -Type Verbose
    }
    process {
        # Resolve input paths
        $originalDirFull = Get-Path -Path $Path -PathType Absolute -ValidatePath Directory
        $outputDirFull = Get-Path -Path $Destination -PathType Absolute -Create Directory
        Write-Message "Processing $originalDirFull for $Language audio streams" -Type Verbose
        # Get filtered audio streams using the centralized function
        $streamResult = Get-FilteredAudioStreams -Path $originalDirFull
        if ($streamResult.Count -eq 0) {
            Write-Message 'No streams found' -Type Warning
            return
        }
        Write-Message "Filtered audio streams ($($streamResult.Count))" -Type Verbose
        # Use centralized temp directory management
        Use-TempDirectory -ScriptBlock {
            param($TempDirectory)
            # Resolve file sizes for size-proportionate progress (time to process scales with file size)
            $streamEntries = foreach ($stream in $streamResult.Values) {
                $file = $stream.File
                $size = 0
                if (Test-Path -LiteralPath $file -PathType Leaf) {
                    $size = (Get-Item -LiteralPath $file).Length
                }
                [PSCustomObject]@{ Stream = $stream; FileSize = $size }
            }
            $totalBytes = ($streamEntries | Measure-Object -Property FileSize -Sum).Sum
            # Start progress tracking for bonus content processing
            $progress = Start-ProgressActivity -Activity 'Bonus Content Processing' -Status 'Starting processing...' -TotalItems $streamResult.Count
            $currentStream = 0
            $processedBytes = 0
            foreach ($entry in $streamEntries) {
                $currentStream++
                $stream = $entry.Stream
                $streams = $stream.Streams
                $file = $stream.File
                $fileSize = $entry.FileSize
                Write-Message "Processing stream $currentStream`: $($stream.File)" -Type Verbose
                # Update progress (size-based when total size known, else item-based)
                $status = "Processing stream $currentStream of $($streamResult.Count)"
                if ($totalBytes -gt 0) {
                    $percentComplete = [int](($processedBytes / $totalBytes) * 100)
                    $progress.Update(@{ PercentComplete = $percentComplete; Status = $status })
                }
                else {
                    $progress.Update(@{ CurrentItem = $currentStream; Status = $status })
                }
                # Get HandBrake options using centralized function
                $handbrakeOptions = Get-HandbrakeOptions -AudioStreams $streams `
                    -Encoder 'x264' -Quality '21' -EncoderPreset 'slow' -EncoderTune 'film' `
                    -EncoderOptions 'ref=3:debloc=1:0:0:subme=8:psy_red=1.00.0.000:trellis=1:rc_lookahead=40:crf=22.0'
                Write-Message 'Processing files' -Type Verbose
                Convert-VideoFiles -Files @($file) -Destination $outputDirFull -Format mp4 -HandbrakeOptions $handbrakeOptions -Force:$Force | Out-Null
                $processedBytes += $fileSize
            }
            # Complete progress
            $progress.Stop(@{ Status = 'Bonus content processing completed' })
        }
        if (-not $Quiet) {
            $count = $streamResult.Count
            $fileWord = if ($count -eq 1) { 'file' } else { 'files' }
            Write-Message "Bonus content processing completed ($count $fileWord)." -Type Success
        }
    }
    end {
        Write-Message 'Done processing. See above for any errors.' -Type Verbose
        Write-Message 'Bonus content processing completed' -Type Verbose
    }
}
