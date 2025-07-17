function Get-PlexMediaInfo {
    <#
    .SYNOPSIS
        Retrieves detailed information about a specific media item from Plex.
    .DESCRIPTION
        Gets comprehensive information about a specific media item including metadata,
        media files, streams, and other detailed information.
    .PARAMETER Connection
        The Plex connection object containing server URL and authentication token.
    .PARAMETER MediaId
        The ID of the media item to retrieve information for.
    .EXAMPLE
        $connection = New-PlexConnection
        Get-PlexMediaInfo $connection -MediaId 12345
    .OUTPUTS
        [PSCustomObject] Object containing detailed media information.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNull()]
        [object]$Connection,
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$MediaId
    )
    try {
        Write-Message "Retrieving media info for ID: $MediaId" -Type Processing
        $requestUri = $Script:PlexApiEndpoints.MediaInfo -f $MediaId
        $response = Invoke-PlexApiRequest $Connection -Uri $requestUri
        if ($response -and $response.MediaContainer -and $response.MediaContainer.Metadata) {
            $mediaInfo = $response.MediaContainer.Metadata[0]
            Write-Message "✅ Successfully retrieved media info for: $($mediaInfo.title)" -Type Success
            return $mediaInfo
        }
        else {
            Write-Message "❌ Failed to retrieve media info - invalid response format" -Type Error
            return $null
        }
    }
    catch {
        Write-Message "❌ Failed to retrieve media info: $($_.Exception.Message)" -Type Error
        throw
    }
} 
