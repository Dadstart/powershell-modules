function Invoke-ChapterExtractionPhase {
    <#
    .SYNOPSIS
        Executes the chapter extraction phase of DVD processing.
    .DESCRIPTION
        Handles the chapter extraction phase by:
        - Creating the chapter directory structure
        - Extracting chapter samples from copied video files
        - Providing detailed feedback about the extraction process
        This function extracts the chapter extraction logic from Invoke-DvdProcessing
        to improve maintainability and testability.
    .PARAMETER SeasonDir
        The season directory where processing is occurring.
    .PARAMETER CopiedFiles
        Array of copied video file paths to process for chapter extraction.
    .PARAMETER ChapterNumber
        The chapter number to extract. Default is 3.
    .PARAMETER ChapterDuration
        The duration in seconds to extract from the chapter. Default is 30.
    .PARAMETER ChapterDirectory
        Optional custom directory name for chapters. Default is 'Chapters'.
    .EXAMPLE
        $stats = Invoke-ChapterExtractionPhase -SeasonDir "C:\Shows\Breaking Bad\Season 01" -CopiedFiles $videoFiles
        Extracts 30-second samples from chapter 3 of all copied video files.
    .EXAMPLE
        $stats = Invoke-ChapterExtractionPhase -SeasonDir "C:\Shows\The Office\Season 03" -CopiedFiles $videoFiles -ChapterNumber 2 -ChapterDuration 45 -ChapterDirectory "Samples"
        Extracts 45-second samples from chapter 2 into a custom "Samples" directory.
    .OUTPUTS
        [PSCustomObject] Object containing processing statistics:
        - Processed: Number of files successfully processed
        - Failed: Number of files that failed processing
        - Total: Total number of files attempted
    .NOTES
        This function requires the DVD module to be installed and available.
        Uses Export-VideoItem for consistent processing across different content types.
        Provides detailed verbose output for troubleshooting.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SeasonDir,
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [string[]]$CopiedFiles,
        [Parameter()]
        [ValidateRange(1, 99)]
        [int]$ChapterNumber = $Script:DefaultChapterNumber,
        [Parameter()]
        [ValidateRange(1, 300)]
        [int]$ChapterDuration = $Script:DefaultChapterDuration,
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$ChapterDirectory = 'Chapters'
    )
    return Invoke-WithErrorHandling -OperationName "Chapter extraction phase" -DefaultReturnValue @{ Processed = 0; Failed = 0; Total = 0 } -ErrorEmoji "🎬" -ScriptBlock {
        Write-Message "🎬 Starting chapter extraction phase" -Type Processing
        Write-Message "Chapter number: $ChapterNumber" -Type Verbose
        Write-Message "Chapter duration: $ChapterDuration seconds" -Type Verbose
        Write-Message "Files to process: $($CopiedFiles.Count)" -Type Verbose
        # Create chapter directory
        $chapterDir = New-ProcessingDirectory -Path (Get-Path -Path $SeasonDir, $ChapterDirectory -PathType Absolute) -Description "chapter"
        # Define the chapter extraction command
        $cmd = {
            return $CopiedFiles | Invoke-ChapterExtraction -ChapterNumber $ChapterNumber -ChapterDuration $ChapterDuration -ChapterDirectory $chapterDir
        }
        # Execute chapter extraction using the centralized export function
        $chapterStats = Export-VideoItem -Path $SeasonDir -Destination $chapterDir -CopiedFiles $CopiedFiles -Command $cmd -ItemType Chapter
        if ($chapterStats.Processed -gt 0) {
            Write-Message "🎬 Chapters extracted: $($chapterStats.Processed)" -Type Processing
        } else {
            Write-Message "⚠️ No chapters were extracted" -Type Warning
        }
        return $chapterStats
    }
} 
