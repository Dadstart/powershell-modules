function Get-EpisodeInfoFromFilename {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Filename,
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [ValidateCount(1, [int]::MaxValue)]
        [PSCustomObject[]]$EpisodeInfo
    )
    try {
        # Try to extract episode number from filename patterns like:
        # "Alias - S02E04 {tvdb 180292}.mkv" or "Alias - s02e04.mkv"
        $episodeMatch = $Filename -match '[Ss](\d{2})[Ee](\d{2})'
        if ($episodeMatch) {
            $seasonNum = [int]$matches[1]
            $episodeNum = [int]$matches[2]
            # Find matching episode info
            $matchingEpisode = $EpisodeInfo | Where-Object {
                $_.SeasonNumber -eq $seasonNum -and $_.EpisodeNumber -eq $episodeNum
            } | Select-Object -First 1
            if ($matchingEpisode) {
                return $matchingEpisode
            }
        }
        return $null
    }
    catch {
        Write-Message "Failed to get episode info from filename: $($_.Exception.Message)" -Type Error
        return $null
    }
}
