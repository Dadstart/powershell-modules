<#
    Subtitle Codec → File Extension Mapping
    | Codec Name | Description | Typical Extension | Extractable with FFmpeg |
    subrip: Text-based subtitles; .srt, .vtt
    webvtt: Web Video Text Tracks; .vtt
    ass / ssa: Advanced SubStation Alpha; .ass, .ssa
    hdmv_pgs_subtitle: Blu-ray bitmap subtitles; .sup
    dvd_subtitle: VOBSUB (DVD bitmap subtitles); .sub + .idx
    mov_text: MP4 embedded text subtitles; .mp4 container
    microdvd: Frame-based text subtitles; .sub
    jacosub: Legacy text format; .jss
    realtext: RealMedia subtitles; .rt
#>
$SubtitleCodecExtensions = @{
    'subrip'            = '.srt'
    'webvtt'            = '.vtt'
    'ass'               = '.ass'
    'ssa'               = '.ssa'
    'hdmv_pgs_subtitle' = '.sup'
    'dvd_subtitle'      = '.sub'
    'mov_text'          = '.mp4'
    'microdvd'          = '.sub'
    'jacosub'           = '.jss'
    'realtext'          = '.rt'
}
function Invoke-CaptionExtraction {
    <#
    .SYNOPSIS
        Extracts captions from a collection of video files.
    .DESCRIPTION
        This function processes a list of video files and extracts SRT captions from each file.
        It creates a captions subdirectory and saves caption files with the same base name as the video files.
    .PARAMETER File
        File to process.
    .PARAMETER Destination
        The directory where extracted caption files will be saved.
    .EXAMPLE
        Get-ChildItem *.mkv | Invoke-CaptionExtraction -Destination "C:\Output"
    .EXAMPLE
        Invoke-CaptionExtraction -File $file -Destination "C:\Output" -WhatIf
    .OUTPUTS
        Returns an object with the following properties:
        - Processed: The number of files that were processed.
        - Skipped: The number of files that were skipped.
        - Destination: The directory where extracted caption files were saved.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [string]$File,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,
        [Parameter()]
        [string]$Language = 'eng'
    )
    begin {
        $processedCount = 0
        $skippedCount = 0
        # TODO: Consider streaming all files at once to Get-MediaStreamCollection
    }
    process {
        try {
            Write-Message "📝 Processing caption extraction for: $File" -Type Processing
            # Use Get-MediaStreamCollection for efficient processing
            $streamCollection = Get-MediaStreamCollection -Path "$File" -Type Subtitle
            if (-not $streamCollection -or $streamCollection.Count -eq 0) {
                Write-Message "⏭️ No subtitle streams found in $File. File will be skipped." -Type Warning
                $skippedCount++
                return
            }
            # Get streams for this file
            $subtitleStreams = $streamCollection.get_Values()[0] | Where-Object { $_.Language -eq $Language }
            if (-not $subtitleStreams) {
                Write-Message "No subtitle streams found for language: $Language in file: $File" -Type Warning
                $skippedCount++
            }
            Write-Message "$($subtitleStreams.Count) subtitle streams found" -Type Debug
            $outputStreamsByCodec = @{}
            foreach ($codec in $SubtitleCodecExtensions.Keys) {
                $matchingStreams = $subtitleStreams | Where-Object { $_.CodecName -eq $codec }
                if ($matchingStreams -and ($matchingStreams.Count -gt 0)) {
                    if ($outputStreamsByCodec.ContainsKey($codec)) {
                        $outputStreamsByCodec[$codec] += $matchingStreams
                    }
                    else {
                        $outputStreamsByCodec[$codec] = @($matchingStreams)
                    }
                }
            }
            $global:outputStreamsByCodec = $outputStreamsByCodec
            foreach ($codec in $outputStreamsByCodec.Keys) {
                $streams = $outputStreamsByCodec[$codec]
                if (-not $streams) {
                    Write-Message "No $codec streams found" -Type Warning
                    continue
                }
                elseif ($streams.Count -gt 1) {
                    Write-Message "⏭️ $File`: multiple $codec subtitles found. Only the first will be processed. You can manually process the rest of the streams." -Type Warning
                    $warningCount++
                }
                $stream = $streams[0]
                $baseName = [System.IO.Path]::GetFileNameWithoutExtension($File)
                $outputPath = Get-Path -Path $Destination, "$baseName$($SubtitleCodecExtensions[$codec])" -PathType Absolute
                if (Test-Path $outputPath) {
                    Write-Message "⚠️  Overwriting existing caption file: $outputPath" -Type Info
                    Remove-Item $outputPath -Force
                }
                Write-Message "Extracting caption $($stream.TypeIndex) from $File to $outputPath" -Type Verbose
                Export-MediaStream -InputPath $File -Type Subtitle -Index $stream.TypeIndex -OutputPath $outputPath
                Write-Message "✅ Successfully extracted caption to: $outputPath" -Type Verbose
                $processedCount++
            }
        }
        catch {
            throw "❌ Error processing captions for: $File. Error: $($_.Exception.Message)"
        }
    }
    end {
        Write-Message "📊 Caption extraction complete: ✅ Processed: $processedCount; ❌ Skipped: $skippedCount" -Type Success
        return @{
            Processed   = $processedCount
            Warning     = $warningCount
            Skipped     = $skippedCount
            Destination = $Destination
        }
    }
}
