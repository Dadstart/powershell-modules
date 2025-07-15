function Get-PlexLibraryItems {
    <#
    .SYNOPSIS
        Retrieves items from a specific Plex library.
    
    .DESCRIPTION
        Gets all items from a specified Plex library including movies, TV shows, episodes,
        music, or other media types. This function provides detailed information about
        each item in the library including metadata, ratings, and file information.
    
    .PARAMETER Credential
        The Plex credential object containing server URL and authentication token.
    
    .PARAMETER LibraryId
        The ID of the library to retrieve items from.
    
    .PARAMETER Limit
        Maximum number of items to return. Defaults to all items.
    
    .PARAMETER Offset
        Number of items to skip. Useful for pagination.
    
    .PARAMETER Sort
        Sort order for the results (titleSort, addedAt, updatedAt, etc.).
    
    .PARAMETER TimeoutSec
        The timeout in seconds for the request. Defaults to 30.
    
    .EXAMPLE
        $cred = Get-PlexCredential
        Get-PlexLibraryItems -Credential $cred -LibraryId 1
        
        Gets all items from library ID 1.
    
    .EXAMPLE
        $cred = Get-PlexCredential
        Get-PlexLibraryItems -Credential $cred -LibraryId 2 -Limit 50 -Sort "titleSort"
        
        Gets the first 50 items from library ID 2, sorted by title.
    
    .OUTPUTS
        [PSCustomObject[]] Array of objects containing library item information.
    
    .NOTES
        This function requires a valid Plex token and library ID.
        Use Get-PlexLibraries to find available library IDs.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Credential,
        
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$LibraryId,
        
        [Parameter()]
        [ValidateRange(1, 10000)]
        [int]$Limit,
        
        [Parameter()]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Offset,
        
        [Parameter()]
        [ValidateSet('titleSort', 'addedAt', 'updatedAt', 'originallyAvailableAt', 'lastViewedAt', 'viewCount', 'rating', 'year', 'title')]
        [string]$Sort,
        
        [Parameter()]
        [ValidateRange(1, 300)]
        [int]$TimeoutSec = $Script:PlexDefaultTimeout
    )
    
    try {
        Write-Message "Retrieving items from library ID: $LibraryId" -Type Processing
        
        # Build the request URI with query parameters
        $requestUri = $Script:PlexApiEndpoints.LibraryItems -f $LibraryId
        
        # Build query parameters
        $queryParams = @()
        if ($Limit) { $queryParams += "X-Plex-Container-Size=$Limit" }
        if ($Offset) { $queryParams += "X-Plex-Container-Start=$Offset" }
        if ($Sort) { $queryParams += "sort=$Sort" }
        
        if ($queryParams.Count -gt 0) {
            $requestUri += "?" + ($queryParams -join "&")
        }
        
        # Make the request
        $response = Invoke-PlexApiRequest -Uri $requestUri -Credential $Credential -TimeoutSec $TimeoutSec
        
        if ($response -and $response.MediaContainer -and $response.MediaContainer.Metadata) {
            $items = $response.MediaContainer.Metadata
            
            # Convert to custom objects
            $result = $items | ForEach-Object {
                [PSCustomObject]@{
                    Id = $_.ratingKey
                    Title = $_.title
                    Type = $_.type
                    Year = $_.year
                    Rating = $_.rating
                    ContentRating = $_.contentRating
                    Summary = $_.summary
                    Duration = $_.duration
                    ViewCount = $_.viewCount
                    LastViewedAt = $_.lastViewedAt
                    AddedAt = $_.addedAt
                    UpdatedAt = $_.updatedAt
                    OriginallyAvailableAt = $_.originallyAvailableAt
                    Studio = $_.studio
                    Tagline = $_.tagline
                    Art = $_.art
                    Thumb = $_.thumb
                    Banner = $_.banner
                    Theme = $_.theme
                    Genre = $_.Genre
                    Director = $_.Director
                    Writer = $_.Writer
                    Country = $_.Country
                    Collection = $_.Collection
                    Role = $_.Role
                    Media = $_.Media
                    Guid = $_.guid
                    LibrarySectionId = $_.librarySectionID
                    LibrarySectionTitle = $_.librarySectionTitle
                    LibrarySectionType = $_.librarySectionType
                    LibrarySectionUUID = $_.librarySectionUUID
                    RatingKey = $_.ratingKey
                    Key = $_.key
                    ParentRatingKey = $_.parentRatingKey
                    GrandparentRatingKey = $_.grandparentRatingKey
                    ParentGuid = $_.parentGuid
                    GrandparentGuid = $_.grandparentGuid
                    ParentStudio = $_.parentStudio
                    ParentKey = $_.parentKey
                    ParentTitle = $_.parentTitle
                    GrandparentKey = $_.grandparentKey
                    GrandparentTitle = $_.grandparentTitle
                    GrandparentTheme = $_.grandparentTheme
                    GrandparentThumb = $_.grandparentThumb
                    GrandparentArt = $_.grandparentArt
                    ParentThumb = $_.parentThumb
                    ParentArt = $_.parentArt
                    ParentTheme = $_.parentTheme
                    ParentIndex = $_.parentIndex
                    GrandparentIndex = $_.grandparentIndex
                    ParentYear = $_.parentYear
                    GrandparentYear = $_.grandparentYear
                    ParentContentRating = $_.parentContentRating
                    GrandparentContentRating = $_.grandparentContentRating
                    ParentSummary = $_.parentSummary
                    GrandparentSummary = $_.grandparentSummary
                    ParentTagline = $_.parentTagline
                    GrandparentTagline = $_.grandparentTagline
                    ParentRating = $_.parentRating
                    GrandparentRating = $_.grandparentRating
                    ParentViewCount = $_.parentViewCount
                    GrandparentViewCount = $_.grandparentViewCount
                    ParentLastViewedAt = $_.parentLastViewedAt
                    GrandparentLastViewedAt = $_.grandparentLastViewedAt
                    ParentAddedAt = $_.parentAddedAt
                    GrandparentAddedAt = $_.grandparentAddedAt
                    ParentUpdatedAt = $_.parentUpdatedAt
                    GrandparentUpdatedAt = $_.grandparentUpdatedAt
                    ParentOriginallyAvailableAt = $_.parentOriginallyAvailableAt
                    GrandparentOriginallyAvailableAt = $_.grandparentOriginallyAvailableAt
                    GrandparentStudio = $_.grandparentStudio
                    ParentGenre = $_.parentGenre
                    GrandparentGenre = $_.grandparentGenre
                    ParentDirector = $_.parentDirector
                    GrandparentDirector = $_.grandparentDirector
                    ParentWriter = $_.parentWriter
                    GrandparentWriter = $_.grandparentWriter
                    ParentCountry = $_.parentCountry
                    GrandparentCountry = $_.grandparentCountry
                    ParentCollection = $_.parentCollection
                    GrandparentCollection = $_.grandparentCollection
                    ParentRole = $_.parentRole
                    GrandparentRole = $_.grandparentRole
                    ParentMedia = $_.parentMedia
                    GrandparentMedia = $_.grandparentMedia
                }
            }
            
            Write-Message "✅ Successfully retrieved $($result.Count) items from library" -Type Success
            
            return $result
        }
        else {
            Write-Message "❌ Failed to retrieve library items - invalid response format" -Type Error
            return @()
        }
    }
    catch {
        Write-Message "❌ Failed to retrieve library items: $($_.Exception.Message)" -Type Error
        throw
    }
} 