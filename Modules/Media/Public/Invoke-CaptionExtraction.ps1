function Invoke-CaptionExtraction {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [string]$File,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Format
    )
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
        Returns a hashtable with processing statistics.
    #>
    begin {
        $processedCount = 0
        $skippedCount = 0
        Write-Message "Invoke-CaptionExtraction: Invoking caption extraction" -Type Verbose
        Write-Message "Invoke-CaptionExtraction: Destination: $Destination" -Type Verbose
    }
    process {
        Write-Message "Invoke-CaptionExtraction: File: $File" -Type Verbose
        try {
            Write-Message "Invoke-CaptionExtraction: 📝 Processing caption extraction for: $File" -Type Verbose
            # Use Get-MediaStreamCollection for efficient processing
            $streamCollection = Get-MediaStreamCollection -Paths @($File) -Type Subtitle
            if (-not $streamCollection -or $streamCollection.Count -eq 0) {
                Write-Message "Invoke-CaptionExtraction: ⏭️ Skipping: $($File) - no subtitle streams found" -Type Verbose
                $skippedCount++
                return
            }
            # Get streams for this file
            $subtitleStreams = $streamCollection[$File]
            if (-not $subtitleStreams) {
                Write-Message "Invoke-CaptionExtraction: ⏭️ Skipping: $($File) - no subtitle streams found" -Type Verbose
                $skippedCount++
                return
            }
            Write-Message "Invoke-CaptionExtraction: $($subtitleStreams.Count) subtitle streams found" -Type Debug
            # Filter for subrip (SRT) captions
            $srtStreams = $subtitleStreams | Where-Object { $_.CodecName -eq 'subrip' }                
            Write-Message "$($srtStreams.Count) SRT streams found" -Type Debug
            if ($srtStreams.Count -eq 0) {
                Write-Message "Invoke-CaptionExtraction: ⏭️ Skipping: $($File) - no SRT captions found" -Type Verbose
                $skippedCount++
                return
            }
            elseif ($srtStreams.Count -gt 1) {
                Write-Message "Invoke-CaptionExtraction: ⏭️ Skipping: $($File) - multiple SRT captions found. Needs manual processing." -Type Warning
                $skippedCount++
                return
            }
            # Process SRT stream
            $stream = $srtStreams[0]
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($File)
            $outputPath = Get-Path -Path $Destination, "$baseName.en.$Format" -PathType Absolute
            # Check if output file exists and inform user about overwriting
            if (Test-Path $outputPath) {
                Write-Message "Invoke-CaptionExtraction: ⚠️  Overwriting existing caption file: $outputPath" -Type Verbose
            }
            Write-Message "Invoke-CaptionExtraction: Extracting caption $($stream.TypeIndex) from $File" -Type Verbose
            # Remove existing file first to ensure clean overwrite
            if (Test-Path $outputPath) {
                Remove-Item $outputPath -Force
            }
            Export-MediaStream -InputPath $File -Type Subtitle -Index $stream.TypeIndex -OutputPath $outputPath
            Write-Message "Invoke-CaptionExtraction: ✅ Successfully extracted caption to: $outputPath" -Type Verbose
            $processedCount++
        }
        catch {
            throw "Invoke-CaptionExtraction: ❌ Error processing captions for: $File. Error: $($_.Exception.Message)"
        }
    }
    end {
        # Caption extraction summary
        Write-Message "Invoke-CaptionExtraction: `n📊 === Caption Extraction Summary ===" -Type Verbose
        Write-Message "Invoke-CaptionExtraction: ✅ Processed: $processedCount" -Type Verbose
        Write-Message "Invoke-CaptionExtraction: ⏭️ Skipped: $skippedCount" -Type Verbose
        Write-Message "Invoke-CaptionExtraction :📁 Output directory: $Destination" -Type Verbose
        return @{
            Processed   = $processedCount
            Skipped     = $skippedCount
            Destination = $Destination
        }
    }
}
