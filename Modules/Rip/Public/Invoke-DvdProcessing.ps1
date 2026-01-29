function Invoke-DvdProcessing {
    <#
    .SYNOPSIS
        Orchestrates a complete DVD processing workflow with automated directory structure creation and content organization.
    .DESCRIPTION
        Invoke-DvdProcessing serves as the main entry point for DVD processing workflows, providing:
        - Automated creation of organized directory structures for content processing
        - Integration with TVDb for metadata retrieval and episode information
        - Chapter and caption extraction from DVD sources
        - Setup of processing stage directories (HandBrake, Remux, Topaz, Bonus)
        - Content organization by season with proper naming conventions
        - Integration with the refactored DVD module functions for optimal performance
        This function leverages the refactored DVD module architecture, which includes:
        - Centralized audio stream processing via Get-FilteredAudioStreams
        - Automated temporary directory management via Use-TempDirectory
        - Standardized HandBrake options generation via Get-HandbrakeOptions
        The workflow ensures all necessary directories and extracted content are properly
        organized for subsequent processing steps using the optimized module functions.
    .PARAMETER Title
        The title of the DVD content to process. Used to create the root directory structure
        and organize content. Should be a descriptive name that identifies the content.
        Examples: "Breaking Bad", "The Office", "The Matrix", "Game of Thrones"
    .PARAMETER Path
        The source directories containing the DVD content files. Can be a single path or multiple
        comma-separated paths. These directories should contain the original DVD files.
        Supported formats: VOB (DVD), M2TS (Blu-ray), MKV (already-ripped content)
        Examples: "D:\DVD1", "D:\DVD1,D:\DVD2", "C:\Rips\Season1"
    .PARAMETER FilePatterns
        Array of file patterns to match for processing. Multiple patterns can be specified
        to handle different file types in the same workflow.
        Common patterns:
        - "*.vob" - DVD video files
        - "*.m2ts" - Blu-ray video files
        - "*.mkv" - Already-ripped content
        - "C4_*" - DVD rips with specific naming
        - "B3_*" - Blu-ray rips with specific naming
    .PARAMETER Season
        The season number for the content. Used to create season-specific directories
        and organize content properly. Should be a number that corresponds to the actual
        season of the content.
        Examples: 1, 2, 5, 10
    .PARAMETER TvDbSeriesUrl
        The TVDb series URL for metadata retrieval. This URL is used to fetch episode
        information, titles, and other metadata throughout the processing workflow.
        Format: "https://thetvdb.com/series/show-name"
        Examples:
        - "https://thetvdb.com/series/breaking-bad"
        - "https://thetvdb.com/series/the-office-us"
        - "https://thetvdb.com/series/game-of-thrones"
    .PARAMETER TvDbSeasonUrl
        Alternative to TvDbSeriesUrl. The direct TVDb season URL. If provided, this will be used
        instead of constructing the season URL from TvDbSeriesUrl.
        Format: "https://thetvdb.com/series/show-name/seasons/official/season-number"
        Examples:
        - "https://thetvdb.com/series/breaking-bad/seasons/official/1"
        - "https://thetvdb.com/series/the-office-us/seasons/official/2"
    .PARAMETER ExtractChapters
        When specified, performs the chapter extraction phase, creating sample chapter clips.
        Default behavior (when not specified) is to skip chapter extraction. Pass this switch
        when you want to extract chapter samples in addition to copying files and captions.
    .PARAMETER SkipCaptionExtraction
        When specified, skips the caption extraction phase. Useful when you only want
        to copy files and extract chapters without processing subtitle files.
        Default behavior (when not specified) is to extract captions.
    .PARAMETER ChapterDirectory
        Directory name for storing extracted chapter clips and sample content. Default is "chapters".
        This directory will contain short clips extracted from $ChapterNumber chapters of the content for preview
        or testing purposes.
        The actual path will be: ./Title/Season XX/chapters/
    .PARAMETER ChapterNumber
        The chapter number to extract for sample clips. Default is 3. This parameter
        determines which chapter from the DVD content will be used to create sample clips.
        Choose a chapter that represents the typical content quality and style.
        Range: 1-999
    .PARAMETER ChapterDuration
        The duration of the chapter to extract in seconds. Default is 30. This determines
        how long the extracted sample clips will be.
        Longer durations provide better samples but require more storage space.
        Range: 1-3600 seconds
    .PARAMETER CaptionDirectory
        The output directory name for extracted captions. Default is "captions".
        This directory will contain all extracted subtitle and caption files in various
        formats for use in subsequent processing steps.
        The actual path will be: ./Title/Season XX/captions/
    .EXAMPLE
        # Process a TV series DVD with standard settings
        Invoke-DvdProcessing -Title "Breaking Bad" -Path "D:\DVD1,D:\DVD2" -FilePatterns "*.vob","*.m2ts" -Season 1 -TvDbSeriesUrl "https://thetvdb.com/series/breaking-bad"
        Creates the directory structure:
        ./Breaking Bad/Season 01/
        ├── clips/         # Extracted sample clips
        ├── captions/      # Extracted captions
        ├── HandBrake/     # For HandBrake conversion
        ├── Remux/         # For remuxing operations
        ├── Topaz/         # For Topaz Video AI
        └── Bonus/         # For bonus content
    .EXAMPLE
        # Process a movie with custom chapter extraction settings
        Invoke-DvdProcessing -Title "The Matrix" -Path "D:\Movie" -FilePatterns "*.vob" -Season 1 -TvDbSeriesUrl "https://thetvdb.com/series/the-matrix" -ChapterNumber 2 -ChapterDuration 45
        Extracts a 45-second clip from chapter 2 instead of the default chapter 3 with 30-second duration.
    .EXAMPLE
        # Process multiple DVD sources with various file types and custom directories
        Invoke-DvdProcessing -Title "Game of Thrones" -Path "D:\DVD1,D:\DVD2,D:\DVD3" -FilePatterns "*.vob","*.m2ts","*.mkv"
                             -Season 2 -TvDbSeriesUrl "https://thetvdb.com/series/game-of-thrones" -SkipCaptionExtraction | Out-Null
        Processes Game of Thrones Season 2 from multiple DVD sources, skipping both chapter
        and caption extraction (chapters skipped by default; -SkipCaptionExtraction skips captions).
    .EXAMPLE
        # Process with specific file patterns for DVD rips
        Invoke-DvdProcessing -Title "The Office" -Path "C:\Rips" -FilePatterns "C4_*","B3_*" -Season 3 -TvDbSeriesUrl "https://thetvdb.com/series/the-office-us"
        Processes The Office Season 3 using specific naming patterns for DVD and Blu-ray rips.
    .EXAMPLE
        # Process with default behavior (skip chapter extraction, extract captions)
        Invoke-DvdProcessing -Title "Breaking Bad" -Path "D:\DVD1" -FilePatterns "*.vob" -Season 1 -TvDbSeriesUrl "https://thetvdb.com/series/breaking-bad"
        Processes Breaking Bad Season 1, copying files and extracting captions. Chapter extraction is skipped by default.
    .EXAMPLE
        # Process without caption extraction (only copy files and extract chapters)
        Invoke-DvdProcessing -Title "Game of Thrones" -Path "D:\DVD1,D:\DVD2" -FilePatterns "*.m2ts" -Season 2 -TvDbSeriesUrl "https://thetvdb.com/series/game-of-thrones" -ExtractChapters -SkipCaptionExtraction
        Processes Game of Thrones Season 2, copying files and extracting chapter samples but skipping caption extraction.
    .NOTES
        PREREQUISITES:
        - Video module must be installed and available
        - TVDb series URL must be valid and accessible
        - Source directories must contain valid DVD/Blu-ray content
        DIRECTORY STRUCTURE:
        The function creates the following organized structure:
        ./Title/Season XX/
        ├── Clips/         # Extracted sample clips (ChapterNumber for ChapterDuration seconds)
        ├── Captions/      # Extracted captions and subtitles
        ├── HandBrake/     # For HandBrake conversion output
        ├── Remux/         # For remuxing operations
        ├── Topaz/         # For Topaz Video AI processing
        └── Bonus/         # For bonus content processing
        REFACTORED ARCHITECTURE:
        This function leverages the refactored DVD module which includes:
        - Centralized audio stream processing (Get-FilteredAudioStreams)
        - Automated temp directory management (Use-TempDirectory)
        - Standardized HandBrake options (Get-HandbrakeOptions)
        All processing is done in a structured manner to ensure consistency and
        reproducibility across different content types and sources.
        ERROR HANDLING:
        - Validates all input parameters before processing
        - Creates directories safely with error handling
        - Provides detailed verbose output for troubleshooting
        - Throws descriptive errors for failed operations
    .LINK
        https://github.com/dadstart/video-modules
    .OUTPUTS
        None. This function creates directories and processes content but does not return objects.
        Success is indicated by:
        - Creation of the directory structure
        - Completion messages in green text
        - Verbose output showing processing steps
        Errors are reported with:
        - Red error messages
        - Detailed exception information
        - Stack traces for debugging
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Path,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$FilePatterns,
        [Parameter(Mandatory)]
        [ValidateRange(1, 1000)]
        [int]$Season,
        [Parameter()]
        [int]$EpisodeStart = 1,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$TvDbSeriesUrl,
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$TvDbSeasonUrl,
        [Parameter()]
        [switch]$ExtractChapters,
        [Parameter()]
        [switch]$SkipCaptionExtraction
    )
    begin {
        Write-Message "🚀 Starting $Title processing" -Type Processing
        Write-Message 'Starting DVD processing workflow' -Type Verbose
        Write-Message "Title: $Title" -Type Verbose
        Write-Message "Directories: $Path" -Type Verbose
        Write-Message "File patterns: $FilePatterns" -Type Verbose
        Write-Message "Season: $Season" -Type Verbose
        if ($TvDbSeasonUrl) {
            Write-Message "TVDb Season URL: $TvDbSeasonUrl" -Type Verbose
        }
        else {
            Write-Message "TVDb URL: $TvDbSeriesUrl" -Type Verbose
        }
    }
    process {
        Invoke-WithErrorHandling -OperationName 'DVD processing' -DefaultReturnValue @() -ErrorEmoji '🎬' -ScriptBlock {
            # Add wildcards to patterns
            $FilePatterns = $FilePatterns | ForEach-Object {
                $val = $_
                if ($_[0] -ne '*') {
                    $val = "*$($_)"
                }
                if ($_[-1] -ne '*') {
                    $val = "$val*"
                }
                return $val
            }
            # Step 1: Create directory structure using the extracted helper function
            $dirStructure = New-ProcessingDirectoryStructure -Title $Title -Season $Season
            $seasonDir = $dirStructure.SeasonDir
            # Step 2: Retrieve TVDb episode information using the season scan function
            $scanParams = @{
                Season = $Season
            }
            if ($TvDbSeasonUrl) {
                $scanParams['TvDbSeasonUrl'] = $TvDbSeasonUrl
            }
            else {
                if (-not $TvDbSeriesUrl) {
                    Write-Message '🚫 Either TvDbSeriesUrl or TvDbSeasonUrl must be provided.' -Type Error
                    return
                }
                $scanParams['TvDbSeriesUrl'] = $TvDbSeriesUrl
            }
            $episodes = Invoke-SeasonScan @scanParams
            if ($episodes.Count -eq 0) {
                Write-Message '🚫 Season scanning failed. Cannot proceed without episode information.' -Type Error
                return
            }
            # Step 3: Copy video files using the centralized video copy function
            $copiedFiles = Invoke-VideoCopy `
                -Path $Path `
                -Destination $seasonDir `
                -Title $Title `
                -Season $Season `
                -Episodes $episodes `
                -FilePatterns $FilePatterns `
                -EpisodeStart $EpisodeStart
            if ($copiedFiles.Count -eq 0) {
                Write-Message '🚫 Video copying failed. Cannot proceed without copied files.' -Type Error
                return
            }
            # Step 4: Chapter extraction phase using the extracted helper function
            if ($ExtractChapters) {
                $chapterStats = Invoke-ChapterExtractionPhase -SeasonDir $seasonDir -CopiedFiles $copiedFiles
            }
            # Step 5: Caption extraction phase using the extracted helper function
            if (-not $SkipCaptionExtraction) {
                $captionStats = Invoke-CaptionExtractionPhase -SeasonDir $seasonDir -CopiedFiles $copiedFiles
            }
            # Final summary
            Write-Message '🎊 DVD processing completed successfully!' -Type Success
            Write-Message "📁 Files copied: $($copiedFiles.Count)" -Type Processing
            Write-Message "📂 Destination: $seasonDir" -Type Processing
            Write-Message '✅ DVD processing completed successfully!' -Type Success
        }
    }
    end {
        Write-Message "DVD processing workflow completed for title: $Title" -Type Verbose
    }
}
