function Invoke-PlexLibraryScan {
    <#
    .SYNOPSIS
        Triggers a library scan on a Plex Media Server.
    .DESCRIPTION
        Initiates a scan of a specified library to detect new media files and update metadata.
        This is useful after adding new content to trigger Plex to recognize and process it.
    .PARAMETER Connection
        The Plex connection object containing server URL and authentication token.
    .PARAMETER LibraryId
        The ID of the library to scan.
    .PARAMETER TimeoutSec
        The timeout in seconds for the request. Defaults to 30.
    .EXAMPLE
        $connection = New-PlexConnection
        Invoke-PlexLibraryScan -Connection $connection -LibraryId 1
    .OUTPUTS
        [bool] True if the scan was initiated successfully, False otherwise.
    #>
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '', Justification = 'PlexCredential is a custom type containing PSCredential, not plain text')]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Connection,
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$LibraryId,
        [Parameter()]
        [ValidateRange(1, 300)]
        [int]$TimeoutSec = $Script:PlexDefaultTimeout
    )
    try {
        Write-Message "Initiating library scan for library ID: $LibraryId" -Type Processing
        $requestUri = $Script:PlexApiEndpoints.LibraryScan -f $LibraryId
        Invoke-PlexApiRequest -Uri $requestUri -Method POST -Connection $Connection -TimeoutSec $TimeoutSec
        Write-Message "✅ Library scan initiated successfully" -Type Success
        return $true
    }
    catch {
        Write-Message "❌ Failed to initiate library scan: $($_.Exception.Message)" -Type Error
        return $false
    }
} 
