function Invoke-VideoCopy {
    <#
    .SYNOPSIS
        Copies and renames video files with TVDb metadata integration.
    .DESCRIPTION
        Handles the video copying phase of DVD processing by:
        - Processing source directories to find video files
        - Filtering files based on size and pattern criteria
        - Copying files to destination with TVDb metadata in filename
        - Providing detailed feedback about the copying process
        - Supporting WhatIf and Confirm operations
        This function centralizes the video copying logic used across
        multiple DVD processing functions.
        Supports pipeline input for Path parameter.
    .PARAMETER Path
        Source directories containing video files to process.
        Supports wildcards and multiple directory paths.
        Can be piped from Get-ChildItem or similar commands.
    .PARAMETER Destination
        Destination directory where copied files will be placed.
    .PARAMETER Title
        The title of the content being processed.
    .PARAMETER Season
        The season number for the content.
    .PARAMETER Episodes
        Array of episode information objects from TVDb.
    .PARAMETER FilePatterns
        Array of file patterns to match for processing.
    .PARAMETER MinimumFileSize
        Minimum file size in bytes for files to be considered valid.
        Default is 100MB.
    .EXAMPLE
        $copiedFiles = Invoke-VideoCopy -Path "C:\Source" -Destination "C:\Output" -Title "Breaking Bad" -Season 1 -Episodes $episodes -FilePatterns "*.mkv"
        Copies Breaking Bad Season 1 files from C:\Source to C:\Output with TVDb metadata.
    .EXAMPLE
        $copiedFiles = Invoke-VideoCopy -Path "D:\Rips\*" -Destination "C:\Processed" -Title "The Office" -Season 3 -Episodes $episodes -FilePatterns "C4_*","B3_*" -MinimumFileSize 2GB
        Copies The Office Season 3 files larger than 2GB matching DVD/Blu-ray patterns.
    .EXAMPLE
        Get-ChildItem -Directory | Invoke-VideoCopy -Destination "C:\Output" -Title "Breaking Bad" -Season 1 -Episodes $episodes -FilePatterns "*.mkv"
        Processes all directories from Get-ChildItem and copies video files with metadata.
    .EXAMPLE
        "C:\Videos", "D:\Movies" | Invoke-VideoCopy -Destination "C:\Output" -Title "The Office" -Season 2 -Episodes $episodes -FilePatterns "*.mp4", "*.mkv"
        Processes multiple directories piped as strings and copies video files with metadata.
    .OUTPUTS
        [string[]] Array of destination file paths that were successfully copied.
        Returns empty array if no files were copied or error occurs.
    .NOTES
        This function requires the Video module to be installed and available.
        Files are filtered by size (minimum 100MB by default) and pattern matching.
        Copied files are renamed with TVDb metadata in the format:
        "{Title} {tvdb {Id}} - s{season}e{episode}.mkv"
        Supports WhatIf and Confirm operations for safe testing.
        Supports pipeline input for flexible directory processing.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,
        [Parameter(Mandatory)]
        [int]$Season,
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$Episodes,
        [ValidateRange(1, 1000)]
        [int]$EpisodeStart = 1,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$FilePatterns,
        [Parameter()]
        [ValidateRange(1, [int]::MaxValue)]
        [long]$MinimumFileSize = 1GB
    )
    begin {
        Write-Message '🎬 Video Copy phase' -Type Processing
        $allPaths = @()
        Write-Message 'Initializing video copy' -Type Verbose
        Write-Message "Destination: $Destination" -Type Verbose
        Write-Message "Title: $Title" -Type Verbose
        Write-Message "Season: $Season" -Type Verbose
        Write-Message "Episode count: $($Episodes.Count)" -Type Verbose
        Write-Message "Episode start: $EpisodeStart" -Type Verbose
        Write-Message "File patterns: $($FilePatterns -join ', ')" -Type Verbose
        Write-Message "Minimum file size: $MinimumFileSize" -Type Verbose
    }
    process {
        if ($Path) {
            $allPaths += $Path
        }
    }
    end {
        return Invoke-WithErrorHandling -OperationName 'Video Copy' -DefaultReturnValue @() -ErrorEmoji '🎬' -ScriptBlock {
            Write-Message "Processing directories: $($allPaths -join ', ')" -Type Verbose
            # Step 1: Get filtered video files using the extracted helper function
            $allAcceptedFiles = Get-FilteredVideoFiles -Path $allPaths -FilePatterns $FilePatterns -MinimumFileSize $MinimumFileSize
            # Check if we have any valid files
            if ($allAcceptedFiles.Count -eq 0) {
                Write-Message '🚫 No valid video files found in any source directories.' -Type Error
                return @()
            }
            # Step 2: Copy files with metadata using the extracted helper function
            $copiedFiles = Copy-FileWithMetadata `
                -Files $allAcceptedFiles `
                -Episodes $Episodes `
                -Destination $Destination `
                -Title $Title `
                -Season $Season `
                -EpisodeStart $EpisodeStart
            return $copiedFiles
        }
        Write-Message 'Invoke-VideoCopy: begin (start)' -Type Processing
    }
}
