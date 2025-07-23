function Invoke-CaptionExtractionPhase {
    <#
    .SYNOPSIS
        Executes the caption extraction phase of DVD processing.
    .DESCRIPTION
        Handles the caption extraction phase by:
        - Creating the caption directory structure
        - Extracting captions in multiple formats (SRT and VTT)
        - Providing detailed feedback about the extraction process
        This function extracts the caption extraction logic from Invoke-DvdProcessing
        to improve maintainability and testability.
    .PARAMETER SeasonDir
        The season directory where processing is occurring.
    .PARAMETER CopiedFiles
        Array of copied video file paths to process for caption extraction.
    .PARAMETER CaptionDirectory
        Optional custom directory name for captions. Default is 'Captions'.
    .EXAMPLE
        $stats = Invoke-CaptionExtractionPhase -SeasonDir "C:\Shows\Breaking Bad\Season 01" -CopiedFiles $videoFiles
        Extracts captions in SRT and VTT formats from all copied video files.
    .EXAMPLE
        $stats = Invoke-CaptionExtractionPhase -SeasonDir "C:\Shows\The Office\Season 03" -CopiedFiles $videoFiles -CaptionDirectory "Subtitles"
        Extracts only SRT captions into a custom "Subtitles" directory.
    .OUTPUTS
        [PSCustomObject] Object containing processing statistics:
        - Processed: Number of files successfully processed
        - Failed: Number of files that failed processing
        - Total: Total number of files attempted
    .NOTES
        This function requires the DVD module to be installed and available.
        Uses Export-VideoItem for consistent processing across different content types.
        Extracts captions in multiple formats for maximum compatibility.
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
        [ValidateNotNullOrEmpty()]
        [string]$CaptionDirectory = 'Captions'
    )
    return Invoke-WithErrorHandling -OperationName 'Caption extraction phase' -DefaultReturnValue @{ Processed = 0; Failed = 0; Total = 0 } -ErrorEmoji "🎬" -ScriptBlock {
        Write-Message '🎬 Starting caption extraction phase' -Type Verbose
        Write-Message "Caption formats: $($Formats -join ', ')" -Type Verbose
        Write-Message "Files to process: $($CopiedFiles.Count)" -Type Verbose
        # Create caption directory
        $captionDir = New-ProcessingDirectory -Path (Get-Path -Path $SeasonDir, $CaptionDirectory -PathType Absolute) -Description 'caption'
        $cmd = { return $CopiedFiles | Invoke-CaptionExtraction -Destination $captionDir }
        # Execute caption extraction using the centralized export function
        $captionStats = Export-VideoItem -Path $SeasonDir -Destination $captionDir -CopiedFiles $CopiedFiles -Command $cmd -ItemType Caption
        if ($captionStats.Processed -gt 0) {
            Write-Message "🎬 Captions extracted: $($captionStats.Processed)" -Type Success
        } else {
            Write-Message '⚠️ No captions were extracted' -Type Warning
        }
        return $captionStats
    }
}
