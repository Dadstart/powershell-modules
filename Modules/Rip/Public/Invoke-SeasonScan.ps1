function Invoke-SeasonScan {
    <#
    .SYNOPSIS
        Scans and retrieves episode information for a TV season from TVDb.
    .DESCRIPTION
        Handles the season scanning phase of DVD processing by:
        - Validating the TVDb series URL
        - Retrieving episode information from TVDb
        - Providing detailed feedback about the scanning process
        - Handling errors gracefully with informative messages
        This function centralizes the episode scanning logic used across
        multiple DVD processing functions.
    .PARAMETER Season
        The season number to scan for episode information.
    .PARAMETER TvDbSeriesUrl
        The TVDb series URL for metadata retrieval.
    .EXAMPLE
        $episodeInfo = Invoke-SeasonScan -Season 1 -TvDbSeriesUrl "https://thetvdb.com/series/breaking-bad"
        Retrieves episode information for Breaking Bad Season 1.
    .EXAMPLE
        $episodeInfo = Invoke-SeasonScan -Season 2 -TvDbSeriesUrl "https://thetvdb.com/series/the-office-us"
        Retrieves episode information for The Office US Season 2.
    .OUTPUTS
        [PSCustomObject[]] Array of episode information objects containing:
        - Id: TVDb episode ID
        - SeasonNumber: Season number
        - Title: Episode title
        - EpisodeNumber: Episode number within the season
        Returns empty array if no episodes found or error occurs.
    .NOTES
        This function requires the Video module to be installed and available.
        The TVDb series URL must be valid and accessible.
        Returns empty array on any error to allow graceful handling by calling functions.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSeasonNumberAttribute()]
        [int]$Season,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$TvDbSeriesUrl
    )
    try {
        Write-Message '🎬 Episode scanning phase' -Type Processing
        Write-Message "Scanning Season $Season from TVDb URL: $TvDbSeriesUrl" -Type Verbose
        # Validate TVDb URL format
        if (-not $TvDbSeriesUrl.StartsWith('https://thetvdb.com/series/')) {
            Write-Message "🚫 Invalid TVDb URL format. Expected: 'https://thetvdb.com/series/show-name'" -Type Error
            Write-Message "💡 Examples: 'https://thetvdb.com/series/breaking-bad', 'https://thetvdb.com/series/the-office-us'" -Type Error
            return @()
        }
        # Retrieve episode information from TVDb
        Write-Message "Retrieving episode information for Season $Season" -Type Verbose
        $episodeInfo = @(Get-TvDbEpisodeInfo -SeriesUrl $TvDbSeriesUrl -SeasonNumber $Season)
        if ($episodeInfo.Count -eq 0) {
            Write-Message "🚫 Failed to retrieve episode information for Season $Season" -Type Error
            Write-Message "💡 Please check the TVDb URL and ensure the season exists" -Type Error
            return @()
        }
        Write-Message "📺 Successfully retrieved $($episodeInfo.Count) episodes for Season $Season" -Type Verbose
        Write-Message "Episode titles: $($episodeInfo.Title -join ', ')" -Type Verbose
        return $episodeInfo
    }
    catch {
        Write-Message "💥 Season scanning failed: $($_.Exception.Message)" -Type Error
        Write-Message "Stack trace: $($_.ScriptStackTrace)" -Type Verbose
        return @()
    }
} 
