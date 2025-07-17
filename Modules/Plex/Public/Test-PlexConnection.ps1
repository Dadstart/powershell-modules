function Test-PlexConnection {
    <#
    .SYNOPSIS
        Tests the connection to a Plex Media Server.
    .DESCRIPTION
        Tests connectivity to a Plex Media Server by making a request to the server info endpoint.
        This function can be used to verify that the Plex server is accessible and responding
        before making other API calls.
    .PARAMETER Connection
        The Plex connection object containing server URL and authentication token.
    .EXAMPLE
        $connection = New-PlexConnection
        Test-PlexConnection $connection
        Tests connectivity to a Plex server using connection.
    .OUTPUTS
        [bool] True if the connection is successful, False otherwise.
    .NOTES
        This function provides a quick way to verify Plex server connectivity
        before attempting more complex operations.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNull()]
        [object]$Connection
    )
    try {
        Write-Message "Testing connection to Plex server: $($Connection.ServerUrl)" -Type Processing
        # Make the test request using relative path
        $response = Invoke-PlexApiRequest $Connection -Uri '/'
        if ($response) {
            Write-Message "✅ Successfully connected to Plex server" -Type Success
            Write-Message "Server version: $($response.MediaContainer.version)" -Type Verbose
            Write-Message "Server name: $($response.MediaContainer.friendlyName)" -Type Verbose
            return $true
        }
        else {
            Write-Message "❌ Failed to connect to Plex server - no response received" -Type Error
            return $false
        }
    }
    catch {
        Write-Message "❌ Failed to connect to Plex server: $($_.Exception.Message)" -Type Error
        return $false
    }
} 
