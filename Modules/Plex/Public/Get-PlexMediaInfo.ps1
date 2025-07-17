function Get-PlexMediaInfo {
    <#
    .SYNOPSIS
        Retrieves detailed information about a specific media item from Plex.
    .DESCRIPTION
        Gets comprehensive information about a specific media item including metadata,
        media files, streams, and other detailed information.
    .PARAMETER Credential
        The Plex credential object containing server URL and authentication token.
    .PARAMETER MediaId
        The ID of the media item to retrieve information for.
    .PARAMETER TimeoutSec
        The timeout in seconds for the request. Defaults to 30.
    .EXAMPLE
        $cred = Get-PlexCredential
        Get-PlexMediaInfo -Credential $cred -MediaId 12345
    .OUTPUTS
        [PSCustomObject] Object containing detailed media information.
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'PlexCredential is a custom type containing PSCredential, not plain text')]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Credential,
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$MediaId,
        [Parameter()]
        [ValidateRange(1, 300)]
        [int]$TimeoutSec = $Script:PlexDefaultTimeout
    )
    try {
        Write-Message "Retrieving media info for ID: $MediaId" -Type Processing
        $requestUri = $Script:PlexApiEndpoints.MediaInfo -f $MediaId
        $response = Invoke-PlexApiRequest -Uri $requestUri -Credential $Credential -TimeoutSec $TimeoutSec
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
