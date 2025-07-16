function Get-TvDbEpisodeInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SeriesUrl,
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 99)]
        [int]$SeasonNumber
    )
    Write-Message "🌐 Retrieving TVDb episode information for Season $SeasonNumber from: $SeriesUrl" -Type Verbose
    try {
        # Validate URL format
        if (-not $SeriesUrl.StartsWith("https://thetvdb.com/series/")) {
            Write-Message "Invalid TVDb URL format. Expected: https://thetvdb.com/series/show-name" -Type Error
            throw "Invalid TVDb URL format. Expected: https://thetvdb.com/series/show-name"
        }
        # Construct the season URL directly
        $seasonUrl = $SeriesUrl + "/seasons/official/$SeasonNumber"
        Write-Message "🔗 Season URL: $seasonUrl" -Type Verbose
        # Get the season page
        Write-Message "📡 Fetching season page..." -Type Verbose
        $seasonRequest = Invoke-WebRequest -Uri $seasonUrl -UseBasicParsing
        # Extract episode links and titles using regex
        # Pattern to match episode links: /series/alias/episodes/299596
        $episodePattern = '/series/[^/]+/episodes/(\d+)'
        $episodeMatches = [regex]::Matches($seasonRequest.Content, $episodePattern)
        if ($episodeMatches.Count -eq 0) {
            Write-Message "❌ No episode IDs found on the season page" -Type Verbose
            return @()
        }
        # Extract the IDs and sort them
        $episodeIds = $episodeMatches | ForEach-Object { $_.Groups[1].Value } | Sort-Object { [int]$_ }
        # Try to extract episode titles
        # Look for title patterns in the HTML content
        $episodeInfo = @()
        for ($i = 0; $i -lt $episodeIds.Count; $i++) {
            $episodeId = $episodeIds[$i]
            # Try to find the episode title by looking for patterns around the episode ID
            # This is a simplified approach - you might need to adjust based on TVDB's actual HTML structure
            $titlePattern = "episodes/$episodeId[^>]*>([^<]+)</a>"
            $titleMatch = [regex]::Match($seasonRequest.Content, $titlePattern)
            $episodeTitle = if ($titleMatch.Success) {
                $titleMatch.Groups[1].Value.Trim()
            } else {
                "Episode $($i + 1)"  # Fallback title
            }
            $episodeInfo += [PSCustomObject]@{
                Id = $episodeId
                SeasonNumber = $SeasonNumber
                Title = $episodeTitle
                EpisodeNumber = $i + 1
            }
        }
        Write-Message "✅ Found $($episodeInfo.Count) episodes for Season $SeasonNumber" -Type Verbose
        foreach ($episode in $episodeInfo) {
            Write-Message "  📺 Episode $($episode.EpisodeNumber): $($episode.Title) (ID: $($episode.Id))" -Type Verbose
        }
        return $episodeInfo
    }
    catch {
        Write-Message "❌ Failed to retrieve episode information: $($_.Exception.Message)" -Type Verbose
        Write-Message "TVDb episode retrieval failed: $($_.Exception.Message)" -Type Error
        throw "TVDb episode retrieval failed: $($_.Exception.Message)"
    }
} 
