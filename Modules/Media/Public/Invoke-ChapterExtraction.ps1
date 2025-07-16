function Invoke-ChapterExtraction {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [string]$File,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ChapterDirectory,
        [Parameter()]
        [ValidateEpisodeNumberAttribute()]
        [int]$ChapterNumber = 2,
        [Parameter()]
        [ValidatePositiveNumberAttribute()]
        [int]$ChapterDuration = 30
    )
    <#
    .SYNOPSIS
        Extracts chapters from a collection of video files.
    .DESCRIPTION
        This function processes a list of video files and extracts specified chapters from each file.
        It creates a clips subdirectory and saves chapter clips with episode-based naming.
    .PARAMETER File
        File name
    .PARAMETER ChapterDirectory
        Directory where the chapter clips will be saved.
    .PARAMETER ChapterNumber
        Chapter number to extract (default: 2).
    .PARAMETER ChapterDuration
        Duration in seconds to extract from each chapter (default: 30).
    .EXAMPLE
        ls *.mkv | Invoke-ChapterExtraction -ChapterDirectory "C:\Output\clips" -ChapterNumber 2
    .EXAMPLE
        Invoke-ChapterExtraction -File $File -ChapterDirectory "C:\Output\clips" -ChapterNumber 2 -WhatIf
    .OUTPUTS
        Returns a hashtable with processing statistics.
    #>
    begin {
        Write-Message "`n🎬 === Chapter Extraction Phase ===" -Type Verbose
        $processedCount = 0
        $skippedCount = 0
        # Create clips subdirectory
        Write-Message "ChapterDirectory: $ChapterDirectory" -Type Debug
        New-ProcessingDirectory -Path $ChapterDirectory -Description 'chapter clips' -SuppressOutput | Out-Null
    }
    process {
        Write-Message "File: $File" -Type Debug
        try {
            # Process each file
            Write-Message "`n🎬 Processing chapter $ChapterNumber extraction for: $File" -Type Verbose
            # Get chapter information from the appropriate file
            $chapter = Get-ChapterInfo -InputFile $File -ChapterNumber $ChapterNumber
            Write-Message "Chapter: $chapter" -Type Debug
            if (-not $chapter) {
                Write-Message "⏭️ Skipping: $File - insufficient chapters" -Type Verbose
                $skippedCount++
                return
            }
            # Extract episode number from the new filename (e.g., s02e04)
            if ($File -match 'e(\d{2})') {
                $episodeNum = $matches[1]
            }
            else {
                $episodeNum = '??'
            }
            Write-Message "Episode number: $episodeNum" -Type Debug
            # Create output filename for chapter: e{episode_number} - chapter {ChapterNumber}.mkv
            Write-Message "ChapterDirectory: $ChapterDirectory" -Type Debug
            Write-Message "ChapterNumber: $ChapterNumber" -Type Debug
            $chapterOutputFile = Get-Path -Path $ChapterDirectory, ("e$episodeNum - chapter $ChapterNumber.mkv") -PathType Absolute
            Write-Message "Chapter output file: $chapterOutputFile" -Type Verbose
            Write-Message "  📥 Input: $File" -Type Verbose
            Write-Message "  📤 Output: $chapterOutputFile" -Type Verbose
            Write-Message "  📖 Chapter: $($chapter.title)" -Type Verbose
            Write-Message "  ⏱️  Start: $($chapter.start_time)s, Duration: $([double]$chapter.end_time - [double]$chapter.start_time)s" -Type Verbose
            # Extract the chapter
            if ($PSCmdlet.ShouldProcess("$File", 'Extract chapter')) {
                Write-Message "Export-Chapter InputFile: $File; OutputFile: $chapterOutputFile; ChapterNumber: $ChapterNumber; MaxDuration: $ChapterDuration" -Type Debug
                $success = Export-Chapter -InputFile $File -OutputFile $chapterOutputFile -ChapterNumber $ChapterNumber -MaxDuration $ChapterDuration
                Write-Message "Export-Chapter success: $success" -Type Debug
                if ($success) {
                    $processedCount++
                }
                else {
                    $skippedCount++
                }
            }
            else {
                Write-Message "WhatIf mode - would extract chapter from $File" -Type Verbose
            }
        }
        catch {
            Write-Message "Chapter extraction failed: $($_.Exception.Message)" -Type Error
            throw "Chapter extraction failed: $($_.Exception.Message)"
        }
    }
    end {
        # Chapter extraction summary
        Write-Message "`n📊 === Chapter Extraction Summary ===" -Type Verbose
        Write-Message "✅ Processed: $processedCount" -Type Verbose
        Write-Message "⏭️ Skipped: $skippedCount" -Type Verbose
        Write-Message "📁 Output directory: $ChapterDirectory" -Type Verbose
        return @{
            Processed   = $processedCount
            Skipped     = $skippedCount
            Destination = $ChapterDirectory
        }
    }
} 
