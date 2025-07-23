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
    .EXAMPLE
        $connection = New-PlexConnection
        Invoke-PlexLibraryScan $connection -LibraryId 1
    .OUTPUTS
        [bool] True if the scan was initiated successfully, False otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNull()]
        [object]$Connection,
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$LibraryId
    )
    try {
        Write-Message "Initiating library scan for library ID: $LibraryId" -Type Processing
        Invoke-PlexApiRequest $Connection [PlexEndpoint]::LibraryScan -Method [WebRequestMethod]::Get.
        Write-Message '✅ Library scan initiated successfully' -Type Success
        return $true
    }
    catch {
        Write-Message "❌ Failed to initiate library scan: $($_.Exception.Message)" -Type Error
        return $false
    }
}
