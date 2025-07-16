function Get-TvDbEpisodeIds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SeriesUrl,
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 99)]
        [int]$SeasonNumber
    )
    try {
        $episodeInfo = Get-TvDbEpisodeInfo -SeriesUrl $SeriesUrl -SeasonNumber $SeasonNumber
        return $episodeInfo.Id
    }
    catch {
        Write-Message "Failed to get TVDb episode IDs: $($_.Exception.Message)" -Type Error
        throw "Failed to get TVDb episode IDs: $($_.Exception.Message)"
    }
} 
